import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// All styles omit color intentionally — color is inherited from the ambient
// DefaultTextStyle, which the MaterialApp theme sets correctly for light/dark/
// high-contrast modes. Only accent/secondary colors are set explicitly.
class AppTextStyles {
  // Nunito: rounded, friendly, game-app energy for all display & headline text
  static TextStyle get displayLarge => GoogleFonts.nunito(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        height: 1.2,
      );

  static TextStyle get headlineLarge => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.25,
      );

  static TextStyle get headlineSmall => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.montserrat(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get labelLarge => GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  // 16 pt minimum — the smallest text shown in the UI.
  static TextStyle get caption => GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get buttonText => GoogleFonts.nunito(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.3,
      );

  static TextStyle get statLarge => GoogleFonts.nunito(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      );

  static TextStyle get statMedium => GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w900,
      );
}
