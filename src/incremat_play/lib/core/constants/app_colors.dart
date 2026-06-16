import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color warmCream = Color(0xFFEFF8F4);
  static const Color sageGreen = Color(0xFF2E9E78);
  static const Color gold = Color(0xFFD4912A);
  static const Color espresso = Color(0xFF2A2424);

  // Supporting
  static const Color lightSage = Color(0xFF96DBC4);
  static const Color forest = Color(0xFF1A6B52);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color subtleText = Color(0xFF6B5E5E);
  static const Color terracotta = Color(0xFFD05040);

  // Dark mode
  static const Color darkBackground = Color(0xFF121712);
  static const Color darkCard = Color(0xFF1C2620);
  static const Color darkSubtle = Color(0xFFB0ABA5);

  // High-contrast light
  static const Color hcBackground = Color(0xFFFFFFFF);
  static const Color hcText = Color(0xFF1A1A1A);
  static const Color hcCard = Color(0xFFF0EDE8);

  // High-contrast accents — sageGreen only reaches ~3.3:1 against white/cream,
  // which fails WCAG AAA (7:1). These replace it when high-contrast is on:
  //   hcAccentLight: white-on-accent ~10:1, accent-on-card ~8.6:1.
  //   hcAccentDark : used on dark backgrounds with espresso text (~9.6:1) and
  //                  reads ~12.8:1 as accent text on near-black.
  static const Color hcAccentLight = Color(0xFF134B37);
  static const Color hcAccentDark = lightSage;

  // High-contrast dark
  static const Color hcDarkBackground = Color(0xFF050505);
  static const Color hcDarkText = Color(0xFFF5F5F5);
  static const Color hcDarkCard = Color(0xFF181414);

  // Pet stage colors
  static const Color eggShell = Color(0xFFF5EDDD);
  static const Color babyBlue = Color(0xFFB8D4E8);
  static const Color youngGreen = Color(0xFFA8C5B5);
  static const Color adultGold = Color(0xFFD4912A);
}
