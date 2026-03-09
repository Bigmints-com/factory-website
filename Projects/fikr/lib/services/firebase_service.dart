import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/subscription_tier.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  late GenerativeModel _model;
  late FirebaseRemoteConfig _remoteConfig;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;
  Rx<User?> currentUser = Rx<User?>(null);

  /// Initialize Firebase services that require specific setup
  Future<void> initialize() async {
    if (_initialized) return;

    // Bind auth state
    currentUser.bindStream(_auth.authStateChanges());

    // Auto sign-in if needed (optional)
    if (_auth.currentUser == null) {
      // await signInAnonymously();
    }

    try {
      // Initialize Firebase AI (Vertex AI)
      _model = FirebaseAI.vertexAI().generativeModel(model: 'gemini-1.5-flash');

      // Initialize Remote Config
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set defaults
      await _remoteConfig.setDefaults(const {
        "allowed_models":
            '{"chat": ["gpt-4o", "gemini-pro"], "transcription": ["whisper-1"]}',
      });

      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      debugPrint('Firebase Services (Vertex AI, Remote Config) initialized.');
    } catch (e) {
      debugPrint('Error initializing Firebase Services: $e');
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      await googleSignIn.authenticate();

      // Get authorization tokens for Firebase credential
      final authorization = await googleSignIn.authorizationClient
          .authorizationForScopes(<String>['email', 'profile']);

      final accessToken = authorization?.accessToken;
      if (accessToken == null) {
        throw Exception('Failed to get access token from Google Sign-In');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Generates a cryptographically secure random nonce.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the SHA-256 hash of [input].
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Apple can return null identityToken on failure
      if (appleCredential.identityToken == null) {
        throw Exception('Apple Sign-In failed: no identity token received.');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple only sends the name on the first sign-in; persist it.
      final displayName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((n) => n != null && n.isNotEmpty).join(' ');

      if (displayName.isNotEmpty &&
          (userCredential.user?.displayName == null ||
              userCredential.user!.displayName!.isEmpty)) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple Sign-In Firebase error: ${e.code} – ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final uid = user.uid;
        final firestore = FirebaseFirestore.instance;
        final userDoc = firestore.collection('users').doc(uid);

        // Delete notes subcollection
        final notes = await userDoc.collection('notes').get();
        for (var doc in notes.docs) {
          await doc.reference.delete();
        }

        // Delete insights subcollection
        final insights = await userDoc.collection('insights').get();
        for (var doc in insights.docs) {
          await doc.reference.delete();
        }

        // Delete user document
        await userDoc.delete();

        // Finally delete the auth user
        await user.delete();
      } catch (e) {
        debugPrint('Error deleting account: $e');
        rethrow;
      }
    }
  }

  /// Get allowed models from Remote Config
  Map<String, List<String>> getAllowedModels() {
    if (!_initialized) return {};
    try {
      final jsonString = _remoteConfig.getString('allowed_models');
      debugPrint('Remote Config allowed_models: $jsonString');
      // In a real implementation, parse this JSON.
      // For now, return empty or implement parsing if dependent.
      return {};
    } catch (e) {
      debugPrint('Error parsing allowed_models: $e');
      return {};
    }
  }

  /// Generate content using Vertex AI
  Future<String?> generateContent(String prompt) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      debugPrint('Error generating content: $e');
      return null;
    }
  }

  /// Transcribe audio using Gemini Flash (multimodal)
  Future<String> transcribeAudio(File audioFile) async {
    if (!_initialized) await initialize();

    try {
      final bytes = await audioFile.readAsBytes();
      // Mime type might need to be specific, typical m4a from recorder is audio/m4a or audio/mp4
      // Gemini supports: audio/wav, audio/mp3, audio/aiff, audio/aac, audio/ogg, audio/flac
      // Recorder uses aacLc, usually inside m4a container.
      const mimeType = 'audio/mp4';

      final content = [
        Content.multi([
          TextPart('Please transcribe this audio file accurately.'),
          InlineDataPart(mimeType, bytes),
        ]),
      ];

      final response = await _model.generateContent(content);
      return response.text ?? '';
    } catch (e) {
      debugPrint('Vertex AI Transcription Error: $e');
      rethrow;
    }
  }

  /// Fetch the subscription tier for [uid] from Firestore (one-time read).
  Future<SubscriptionTier> getUserSubscriptionTier(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) return SubscriptionTier.free;
      final data = doc.data();
      final tierStr = data?['plan'] as String?;
      return SubscriptionTier.values.firstWhere(
        (t) => t.name == tierStr,
        orElse: () => SubscriptionTier.free,
      );
    } catch (e) {
      debugPrint('Error fetching subscription tier: $e');
      return SubscriptionTier.free;
    }
  }

  /// Returns a stream of [SubscriptionTier] for [uid] that updates live.
  Stream<SubscriptionTier> userTierStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return SubscriptionTier.free;
      final tierStr = snap.data()?['plan'] as String?;
      return SubscriptionTier.values.firstWhere(
        (t) => t.name == tierStr,
        orElse: () => SubscriptionTier.free,
      );
    });
  }

  /// Analyze transcript using Gemini Flash
  Future<Map<String, dynamic>> analyzeTranscript({
    required String transcript,
    required List<String> buckets,
  }) async {
    if (!_initialized) await initialize();

    final bucketList = buckets.join(', ');
    final prompt =
        '''
    You are an assistant that cleans spoken notes into structured text.
    Return ONLY valid JSON with keys: "cleanedText", "intent", "bucket", "topics".
    Rules:
    1. Pick exactly ONE bucket from this list: $bucketList. If none fit, use "General". Put this in "bucket".
    2. Identify 3-5 relevant tags/topics for metadata and put them in "topics".
    3. Provide a concise title in "intent" and cleaned version of the transcript in "cleanedText".
    
    Transcript:
    $transcript
    ''';

    try {
      // Use generationConfig to enforce JSON if possible, or just ask nicely (Flash is good at JSON)
      final content = [Content.text(prompt)];

      // Note: You can pass generationConfig: GenerationConfig(responseMimeType: 'application/json')
      // but the current wrapper might vary. Let's try standard prompt first or check constructor.
      // Re-initializing a specific model for JSON mode if needed, but standard model should work.

      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null) throw Exception('No response from Vertex AI');

      // Basic cleanup for markdown json blocks
      final cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Need to import dart:convert
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Vertex AI Analysis Error: $e');
      rethrow;
    }
  }
}
