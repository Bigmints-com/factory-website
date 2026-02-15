import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../models/note.dart';
import '../models/insights_models.dart';
import '../controllers/app_controller.dart';
import '../services/storage_service.dart';
import '../services/toast_service.dart';
import '../services/firebase_service.dart';
import '../controllers/subscription_controller.dart';

/// Key used to persist the last-synced user ID so we can detect
/// same-account re-login vs account switches.
const _kLastSyncedUserKey = 'last_synced_user_id';

class SyncService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _prefs = const FlutterSecureStorage();

  final RxBool isSyncEnabled = false.obs;
  bool _isSyncing = false;

  @override
  void onInit() {
    super.onInit();

    // React to auth changes
    ever(FirebaseService().currentUser, (user) {
      debugPrint('Sync: Auth changed → ${user?.uid ?? 'signed-out'}');
      if (user != null && !user.isAnonymous) {
        _handleLogin(user);
      }
      // Logout: do nothing — keep local data in place.
    });

    // React to plan changes (re-push user record)
    final subController = Get.find<SubscriptionController>();
    ever(subController.currentTier, (tier) {
      debugPrint('Sync: Plan changed → ${tier.name}');
      if (FirebaseService().currentUser.value != null) {
        _startSync();
      }
    });

    // Boot check: if already logged in, sync immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseService().currentUser.value;
      if (user != null && !user.isAnonymous) {
        debugPrint('Sync: User found on boot, starting sync.');
        _handleLogin(user);
      }
    });
  }

  void setSyncEnabled(bool enabled) {
    isSyncEnabled.value = enabled;
    if (enabled) {
      final user = _auth.currentUser;
      if (user != null && !user.isAnonymous) {
        _handleLogin(user);
      }
    }
  }

  // ── Core login handler ─────────────────────────────────────────────

  /// Decides what to do when a user logs in:
  ///  • Same account as last sync → bidirectional merge (newer wins)
  ///  • Different account          → clear local, pull cloud data
  ///  • First-ever login           → push local notes to cloud
  Future<void> _handleLogin(User user) async {
    if (_isSyncing) {
      debugPrint('Sync: Already in progress, skipping.');
      return;
    }
    _isSyncing = true;

    try {
      final lastSyncedUid = await _prefs.read(key: _kLastSyncedUserKey);
      debugPrint('Sync: Current=${user.uid}, LastSynced=$lastSyncedUid');

      if (lastSyncedUid == null) {
        // ── First-ever login: push local data to cloud ──────────
        debugPrint('Sync: First login — pushing local data to cloud.');
        await syncToCloud();
        await _prefs.write(key: _kLastSyncedUserKey, value: user.uid);
      } else if (lastSyncedUid == user.uid) {
        // ── Same account re-login: bidirectional merge ──────────
        debugPrint('Sync: Same account — merging.');
        await _syncBidirectional();
      } else {
        // ── Different account: clear local, pull new user's data ─
        debugPrint('Sync: Account switch — clearing local & pulling cloud.');
        await _clearLocalData();
        await _pullCloudData(user.uid);
        await _prefs.write(key: _kLastSyncedUserKey, value: user.uid);
      }

      _refreshAppController();
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ── Backward-compat wrapper used by plan-change listener ───────────

  Future<void> _startSync() async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      await _handleLogin(user);
    }
  }

  // ── Bidirectional merge (same account) ─────────────────────────────

  Future<void> _syncBidirectional() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    // Pull cloud notes & insights
    final cloudNotesSnap = await userRef.collection('notes').get();
    final cloudNotes = cloudNotesSnap.docs
        .map((d) => Note.fromJson(d.data()))
        .toList();

    final cloudInsightsSnap = await userRef.collection('insights').get();
    final cloudInsights = cloudInsightsSnap.docs
        .map((d) => InsightEdition.fromJson(d.data()))
        .toList();

    // Load local data
    final localNotes = await _storage.loadNotes();
    final localInsights = await _storage.loadInsightEditions();

    // Merge (newer wins)
    final mergedNotes = _mergeNotes(localNotes, cloudNotes);
    final mergedInsights = _mergeInsights(localInsights, cloudInsights);

    // Save merged locally
    await _storage.saveNotes(mergedNotes);
    await _storage.saveInsightEditions(mergedInsights);

    // Push merged to cloud
    await syncToCloud();

    debugPrint(
      'Sync: Merge complete. Notes: ${mergedNotes.length}, '
      'Insights: ${mergedInsights.length}',
    );
  }

  // ── Pull cloud data (account switch) ───────────────────────────────

  Future<void> _pullCloudData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);

    final cloudNotesSnap = await userRef.collection('notes').get();
    final cloudNotes = cloudNotesSnap.docs
        .map((d) => Note.fromJson(d.data()))
        .toList();

    final cloudInsightsSnap = await userRef.collection('insights').get();
    final cloudInsights = cloudInsightsSnap.docs
        .map((d) => InsightEdition.fromJson(d.data()))
        .toList();

    await _storage.saveNotes(cloudNotes);
    await _storage.saveInsightEditions(cloudInsights);

    debugPrint(
      'Sync: Pulled cloud data. Notes: ${cloudNotes.length}, '
      'Insights: ${cloudInsights.length}',
    );
  }

  // ── Clear local data (account switch only) ─────────────────────────

  Future<void> _clearLocalData() async {
    debugPrint('Sync: Clearing local data for account switch.');
    await _storage.saveNotes([]);
    await _storage.saveInsightEditions([]);
    _refreshAppController();
  }

  // ── Refresh in-memory AppController lists ──────────────────────────

  void _refreshAppController() {
    try {
      final appController = Get.find<AppController>();
      _storage.loadNotes().then((notes) {
        appController.notes.value = notes.where((n) => !n.archived).toList();
      });
      _storage.loadInsightEditions().then((editions) {
        appController.insightEditions.value = editions;
      });
    } catch (_) {
      // AppController may not be registered yet during startup
    }
  }

  // ── Merge helpers ──────────────────────────────────────────────────

  List<Note> _mergeNotes(List<Note> local, List<Note> cloud) {
    final Map<String, Note> merged = {};
    for (final note in local) {
      merged[note.id] = note;
    }
    for (final cloudNote in cloud) {
      final existing = merged[cloudNote.id];
      if (existing == null || cloudNote.updatedAt.isAfter(existing.updatedAt)) {
        merged[cloudNote.id] = cloudNote;
      }
    }
    return merged.values.toList();
  }

  List<InsightEdition> _mergeInsights(
    List<InsightEdition> local,
    List<InsightEdition> cloud,
  ) {
    final Map<String, InsightEdition> merged = {};
    for (final edition in local) {
      merged[edition.id] = edition;
    }
    for (final cloudEdition in cloud) {
      if (!merged.containsKey(cloudEdition.id)) {
        merged[cloudEdition.id] = cloudEdition;
      }
    }
    return merged.values.toList();
  }

  // ── Public: push to cloud ──────────────────────────────────────────

  /// Delete a specific note from Firestore so it won't come back on sync.
  Future<void> deleteNoteFromCloud(String noteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .delete();
      debugPrint('Sync: Deleted note $noteId from cloud.');
    } catch (e) {
      debugPrint('Sync: Error deleting note from cloud: $e');
    }
  }

  Future<void> syncToCloud() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('SyncToCloud: No user logged in.');
        return;
      }

      debugPrint('SyncToCloud: Pushing data for ${user.uid}');

      final notes = await _storage.loadNotes();
      final insights = await _storage.loadInsightEditions();
      final config = await _storage.loadConfig();

      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(user.uid);

      // Notes
      for (final note in notes) {
        batch.set(
          userRef.collection('notes').doc(note.id),
          note.toJson(),
          SetOptions(merge: true),
        );
      }

      // Insights
      for (final edition in insights) {
        batch.set(
          userRef.collection('insights').doc(edition.id),
          edition.toJson(),
          SetOptions(merge: true),
        );
      }

      // User document
      final subController = Get.find<SubscriptionController>();
      batch.set(userRef, {
        'email': user.email,
        'plan': subController.currentTier.value.name,
        'config': config.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      // Persist this user ID as the last synced account
      await _prefs.write(key: _kLastSyncedUserKey, value: user.uid);

      debugPrint('SyncToCloud: Complete.');
    } catch (e) {
      debugPrint('SyncToCloud Error: $e');
      if (Get.context != null) {
        ToastService.showError(
          Get.context!,
          title: 'Sync Failed',
          description: 'Could not backup data. Please try again.',
        );
      }
    }
  }

  // ── Legacy public accessor (used by auth_screen, settings, etc.) ───

  /// Kept for backward compatibility with screens that call syncFromCloud.
  Future<void> syncFromCloud() async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      await _handleLogin(user);
    }
  }
}
