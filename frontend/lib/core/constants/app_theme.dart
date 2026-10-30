import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const String headingFont = 'Fraunces';
  static const String bodyFont = 'DMSans';

  // Başlık stilleri (Fraunces) — ekranlarda TextStyle yerine bunlar kullanılır
  static const TextStyle displayLarge = TextStyle(
    fontFamily: headingFont,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.15,
    color: AppColors.textDark,
  );
  static const TextStyle titleLarge = TextStyle(
    fontFamily: headingFont,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: headingFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextTheme _textTheme = TextTheme(
    displayLarge: displayLarge,
    headlineMedium: titleLarge,
    titleLarge: titleMedium,
    titleMedium: TextStyle(fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: bodyFont,
      textTheme: _textTheme
          .apply(bodyColor: AppColors.textDark, displayColor: AppColors.textDark),
      scaffoldBackgroundColor: AppColors.bgCanvas,
      primaryColor: AppColors.primaryTeal,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryTeal,
        secondary: AppColors.ciniBordeaux,
        surface: AppColors.cardBg,
      ),

      // Yumuşak kart yapısı
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
      ),

      // Birincil butonlar
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // İkincil / Gri butonlar
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          backgroundColor: AppColors.chipInactiveBg,
          side: const BorderSide(color: AppColors.chipBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // AppBar Stili
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}