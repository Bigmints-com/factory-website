import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/app_controller.dart';
import 'controllers/theme_controller.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appController = Get.put(AppController());
  final themeController = Get.put(ThemeController());
  await appController.initialize();
  runApp(const VoiceToThoughtsApp());
}

class VoiceToThoughtsApp extends StatelessWidget {
  const VoiceToThoughtsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voice-to-Thoughts',
      theme: ThemeController.lightTheme,
      darkTheme: ThemeController.darkTheme,
      themeMode: ThemeMode.system,
      home: HomeShell(),
    );
  }
}
