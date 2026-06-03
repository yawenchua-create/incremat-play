import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData light({bool highContrast = false}) {
    final bg = highContrast ? AppColors.hcBackground : AppColors.warmCream;
    final surface = highContrast ? AppColors.hcCard : AppColors.cardSurface;
    final onSurface = highContrast ? AppColors.hcText : AppColors.espresso;

    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme
        .apply(fontFamily: GoogleFonts.montserrat().fontFamily)
        .apply(bodyColor: onSurface, displayColor: onSurface);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: AppColors.sageGreen,
        secondary: AppColors.gold,
        surface: surface,
        error: AppColors.terracotta,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
        outline: highContrast ? onSurface : AppColors.lightSage,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sageGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sageGreen,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          side: BorderSide(
            color: highContrast ? onSurface : AppColors.sageGreen,
            width: highContrast ? 2 : 1,
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: highContrast
              ? BorderSide(color: onSurface, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: highContrast
              ? BorderSide(color: onSurface, width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.sageGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.montserrat(
          fontSize: 16,
          color: AppColors.subtleText,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: highContrast ? 0 : 2,
        shadowColor: AppColors.sageGreen.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: highContrast
              ? BorderSide(color: onSurface.withValues(alpha: 0.2), width: 1.5)
              : BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.sageGreen.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? AppColors.sageGreen
                : onSurface.withValues(alpha: 0.55),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 26,
            color: selected
                ? AppColors.sageGreen
                : onSurface.withValues(alpha: 0.55),
          );
        }),
      ),
      visualDensity: VisualDensity.comfortable,
    );
  }

  static ThemeData dark({bool highContrast = false}) {
    final bg =
        highContrast ? AppColors.hcDarkBackground : AppColors.darkBackground;
    final surface =
        highContrast ? AppColors.hcDarkCard : AppColors.darkCard;
    final onSurface =
        highContrast ? AppColors.hcDarkText : const Color(0xFFF0EBE8);

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = base.textTheme
        .apply(fontFamily: GoogleFonts.montserrat().fontFamily)
        .apply(bodyColor: onSurface, displayColor: onSurface);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.sageGreen,
        secondary: AppColors.gold,
        surface: surface,
        error: AppColors.terracotta,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
        outline: highContrast ? onSurface : AppColors.darkSubtle,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sageGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: highContrast
              ? BorderSide(color: onSurface, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: highContrast
              ? BorderSide(color: onSurface, width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.sageGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: GoogleFonts.montserrat(
          fontSize: 16,
          color: AppColors.darkSubtle,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: highContrast
              ? BorderSide(color: onSurface.withValues(alpha: 0.25), width: 1.5)
              : BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.sageGreen.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? AppColors.sageGreen
                : onSurface.withValues(alpha: 0.55),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 26,
            color: selected
                ? AppColors.sageGreen
                : onSurface.withValues(alpha: 0.55),
          );
        }),
      ),
      visualDensity: VisualDensity.comfortable,
    );
  }
}
