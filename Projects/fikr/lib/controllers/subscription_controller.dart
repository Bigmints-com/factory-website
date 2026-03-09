import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../services/firebase_service.dart';
import '../services/storage_service.dart';

enum SubscriptionTier { free, plus, pro, proPlus }

/// Controller that reflects the user's subscription tier from Firestore.
class SubscriptionController extends GetxController {
  // ignore: unused_field
  final StorageService _storage = Get.find<StorageService>();
  final FirebaseService _firebase = FirebaseService();

  StreamSubscription? _tierSub;

  final Rx<SubscriptionTier> currentTier = SubscriptionTier.free.obs;
  final RxBool isLoading = false.obs;
  final RxBool isAvailable = false.obs;

  // Entitlements
  bool get canSync =>
      currentTier.value == SubscriptionTier.plus ||
      currentTier.value == SubscriptionTier.pro ||
      currentTier.value == SubscriptionTier.proPlus;

  bool get hasAdvancedAI =>
      currentTier.value == SubscriptionTier.pro ||
      currentTier.value == SubscriptionTier.proPlus;

  bool get needsOwnKeys =>
      currentTier.value == SubscriptionTier.free ||
      currentTier.value == SubscriptionTier.plus;

  bool get isPro =>
      currentTier.value == SubscriptionTier.pro ||
      currentTier.value == SubscriptionTier.proPlus;

  // Vertex AI Access
  bool get hasManagedVertexAI =>
      currentTier.value == SubscriptionTier.pro ||
      currentTier.value == SubscriptionTier.proPlus;

  int get tokenLimit {
    switch (currentTier.value) {
      case SubscriptionTier.pro:
        return 1000; // Define appropriate limits
      case SubscriptionTier.proPlus:
        return 5000;
      default:
        return 0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    ever(_firebase.currentUser, (_) => _refreshTier());
    _refreshTier();
  }

  @override
  void onClose() {
    _tierSub?.cancel();
    super.onClose();
  }

  Future<void> _refreshTier() async {
    final user = _firebase.currentUser.value;
    if (user == null) {
      currentTier.value = SubscriptionTier.free;
      _tierSub?.cancel();
      return;
    }
    currentTier.value = await _firebase.getUserSubscriptionTier(user.uid);
    _listenToTierChanges(user.uid);
  }

  void _listenToTierChanges(String uid) {
    _tierSub?.cancel();
    _tierSub = _firebase.userTierStream(uid).listen(
      (tier) => currentTier.value = tier,
      onError: (e) => debugPrint('Tier stream error: $e'),
    );
  }
}
