import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle get _baseStyle => GoogleFonts.quicksand();

  // Display
  static TextStyle get displayLarge =>
      _baseStyle.copyWith(fontSize: 57, fontWeight: FontWeight.w600);
  static TextStyle get displayMedium =>
      _baseStyle.copyWith(fontSize: 45, fontWeight: FontWeight.w600);
  static TextStyle get displaySmall =>
      _baseStyle.copyWith(fontSize: 36, fontWeight: FontWeight.w600);

  // Headline
  static TextStyle get headlineLarge =>
      _baseStyle.copyWith(fontSize: 32, fontWeight: FontWeight.w600);
  static TextStyle get headlineMedium =>
      _baseStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w600);
  static TextStyle get headlineSmall =>
      _baseStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w600);

  // Title
  static TextStyle get titleLarge =>
      _baseStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w800);
  static TextStyle get titleMedium =>
      _baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle get titleSmall =>
      _baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w600);

  // Body
  static TextStyle get bodyLarge =>
      _baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get bodyMedium =>
      _baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get bodySmall =>
      _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w400);

  // Label
  static TextStyle get labelLarge =>
      _baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w500);
  static TextStyle get labelMedium =>
      _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500);
  static TextStyle get labelSmall =>
      _baseStyle.copyWith(fontSize: 11, fontWeight: FontWeight.w500);

  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}
