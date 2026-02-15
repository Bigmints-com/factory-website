import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:toastification/toastification.dart';

import 'controllers/app_controller.dart';
import 'controllers/theme_controller.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_service.dart';
import 'services/storage_service.dart';
import 'services/openai_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Service (Vertex AI)
  await FirebaseService().initialize();

  // Setup Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Get token for debugging
  try {
    String? fcmToken;
    // On Apple platforms, we need to wait for APNS token
    // However, for simplicity in this debug check, we just try/catch
    // or check getAPNSToken if relevant, but handling the specific error is safest.
    fcmToken = await messaging.getToken();
    debugPrint('FCM Token: $fcmToken');
  } catch (e) {
    debugPrint('Failed to get FCM token (likely APNS not ready): $e');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );
      // Show toast or snackbar
    }
  });

  // Analytics example
  await FirebaseAnalytics.instance.logAppOpen();

  // Inject Dependencies
  Get.put(StorageService());
  Get.put(LLMService());

  final appController = Get.put(AppController());
  Get.put(ThemeController());
  await appController.initialize();
  runApp(const FikrApp());
}

class FikrApp extends StatelessWidget {
  const FikrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fikr',
        theme: ThemeController.lightTheme,
        darkTheme: ThemeController.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
