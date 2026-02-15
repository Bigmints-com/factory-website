import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_typography.dart';

class AppPalette {
  static const Color primary = Color(0xFF3CA6A6);
  static const Color secondary = Color.fromARGB(255, 158, 61, 255);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color surfaceLight = Colors.white;
  static const Color onSurfaceLight = Color(0xFF111827);
  static const Color surfaceContainerHighestLight = Color(0xFFF3F4F6);
  static const Color outlineLight = Color.fromARGB(255, 203, 206, 212);
  static const Color shadowLight = Color(0x0A000000);
  static const Color textBodyLight = Color(0xFF4B5563);
  static const Color textLabelLight = Color(0xFF6B7280);
  static const Color inputFillLight = Color(0xFFF1F3F7);

  // Dark Theme Colors
  static const Color backgroundDark = Color.fromARGB(255, 17, 17, 17);
  static const Color surfaceDark = Color.fromARGB(255, 22, 22, 22);
  static const Color onSurfaceDark = Color(0xFFF3F4F6);
  static const Color surfaceContainerHighestDark = Color.fromARGB(
    255,
    47,
    47,
    47,
  );
  static const Color outlineDark = Color.fromARGB(255, 31, 31, 31);
  static const Color shadowDark = Color(0x40000000); // approx 25% opacity black
  static const Color textBodyDark = Color(0xFF9CA3AF);
  static const Color buttonBackgroundDark = Color(0xFF1E293B);
  static const Color buttonBorderDark = Color.fromARGB(255, 85, 85, 85);
}

class ThemeController extends GetxController {
  late final Rx<ThemeMode> themeMode;

  @override
  void onInit() {
    super.onInit();
    themeMode = ThemeMode.system.obs;
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppPalette.primary,
        onPrimary: Colors.white,
        secondary: AppPalette.secondary,
        onSecondary: Colors.black,
        surface: AppPalette.surfaceLight,
        onSurface: AppPalette.onSurfaceLight,
        surfaceContainerHighest: AppPalette.surfaceContainerHighestLight,
        outline: AppPalette.outlineLight,
        shadow: AppPalette.shadowLight,
      ),
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppPalette.onSurfaceLight,
        displayColor: AppPalette.onSurfaceLight,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppPalette.outlineLight),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: AppPalette.outlineLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        disabledColor: AppPalette.surfaceContainerHighestLight,
        selectedColor: Colors.black,
        secondarySelectedColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: AppTypography.labelLarge.copyWith(color: Colors.black),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppPalette.outlineLight, width: 1),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.backgroundLight,
        foregroundColor: AppPalette.onSurfaceLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.white,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppPalette.outlineLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF374151), // Keep as is or add to palette if generic
        textColor: AppPalette.onSurfaceLight,
        tileColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: AppPalette.outlineLight),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.inputFillLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppPalette.onSurfaceLight;
          }),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppPalette.onSurfaceLight;
          }),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppPalette.primary,
        onPrimary: Colors.black,
        secondary: AppPalette.secondary,
        onSecondary: Colors.white,
        surface: AppPalette.surfaceDark,
        onSurface: AppPalette.onSurfaceDark,
        surfaceContainerHighest: AppPalette.surfaceContainerHighestDark,
        outline: AppPalette.outlineDark,
        shadow: AppPalette.shadowDark,
      ),
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppPalette.onSurfaceDark,
        displayColor: AppPalette.onSurfaceDark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.buttonBackgroundDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppPalette.buttonBorderDark),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppPalette.buttonBorderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.surfaceDark,
        disabledColor: AppPalette.surfaceContainerHighestDark,
        selectedColor: Colors.white,
        secondarySelectedColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: AppTypography.labelLarge.copyWith(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppPalette.outlineDark, width: 1),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.backgroundDark,
        foregroundColor: AppPalette.onSurfaceDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: AppPalette.surfaceDark,
        color: AppPalette.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppPalette.outlineDark),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.transparent, width: 0),
        ),
        iconColor: const Color(
          0xFFE5E7EB,
        ), // Keep existing logic for now or move to palette
        textColor: const Color(0xFFE5E7EB), // Keep existing logic
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.surfaceContainerHighestDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppPalette.onSurfaceDark;
          }),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppPalette.onSurfaceDark;
          }),
        ),
      ),
    );
  }
}
