import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeController extends GetxController {
  late final RxBool isDarkMode;

  @override
  void onInit() {
    super.onInit();
    // Initialize based on system theme
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    isDarkMode = (brightness == Brightness.dark).obs;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  static ThemeData get lightTheme {
    const background = Color(0xFFF7F3F0);
    const surface = Color(0xFFFFFFFF);
    const primary = Color(0xFF7B61FF);
    const secondary = Color(0xFFFF9DB5);
    const accent = Color(0xFFFCCB7E);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: Color(0xFFDC2626),
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: Color(0xFF1F1B2E),
        onSurface: Color(0xFF1F1B2E),
        onError: Color(0xFFFFFFFF),
      ),
      textTheme:
          GoogleFonts.plusJakartaSansTextTheme(
            ThemeData.light().textTheme,
          ).copyWith(
            displaySmall: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1B2E),
            ),
            titleLarge: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F1B2E),
            ),
            bodyLarge: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF1F1B2E),
            ),
            bodyMedium: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF6B657A),
            ),
          ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFE7E1DA)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1F1B2E)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1F1B2E),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: accent,
      useMaterial3: false,
    );
  }

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF14121B);
    const darkSurface = Color(0xFF1C1926);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9B8CFF),
        secondary: Color(0xFFF7A1B7),
        surface: darkSurface,
        error: Color(0xFFFF5C6A),
        onPrimary: Color(0xFF1C1926),
        onSecondary: Color(0xFF1C1926),
        onSurface: Color(0xFFFFFFFF),
        onError: Color(0xFFFFFFFF),
      ),
      textTheme:
          GoogleFonts.plusJakartaSansTextTheme(
            ThemeData.dark().textTheme,
          ).copyWith(
            displaySmall: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
            ),
          ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      useMaterial3: false,
    );
  }
}
