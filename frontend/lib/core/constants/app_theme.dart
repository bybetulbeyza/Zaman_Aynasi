import 'package:flutter/material.dart';
import '../state/app_accessibility.dart';
import 'app_colors.dart';

class AppTheme {
  static const String headingFont = 'Fraunces';
  static const String bodyFont = 'DMSans';

  /// Yalnızca marka adı ("Zaman Aynası") için kullanılan yüksek kontrastlı serif.
  static const String brandFont = 'Playfair';

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

  static ThemeData get lightTheme => themeFor(dark: false);

  /// Koyu modda arayüz renk filtresinden geçtiği için, filtre sonrası istenen renklerin
  /// filtre öncesi karşılıkları kullanılır (bkz. AppAccessibility.darkPre).
  static ThemeData themeFor({required bool dark}) {
    final bordeaux = dark
        ? AppAccessibility.darkPre(const Color(0xFFE5808F))
        : AppColors.ciniBordeaux;
    final scrim = dark ? Colors.white.withValues(alpha: 0.62) : Colors.black54;
    final canvas = dark
        ? AppAccessibility.darkPre(const Color(0xFF16272E))
        : AppColors.bgCanvas;
    return ThemeData(
      useMaterial3: true,
      fontFamily: bodyFont,
      textTheme: _textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      scaffoldBackgroundColor: canvas,
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
          backgroundColor: AppColors.ciniBordeauxLight,
          foregroundColor: bordeaux,
          elevation: 0,
          side: BorderSide(color: bordeaux.withValues(alpha: 0.5), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: bordeaux),
      ),

      // Kart/diyalog açılırken arkadaki karartma: koyu modda renk filtresi siyahı beyaza çevirip
      // ekranı AYDINLATTIĞI için, filtre sonrası koyu görünecek açık bir ön renk kullanılır.
      bottomSheetTheme: BottomSheetThemeData(modalBarrierColor: scrim),
      dialogTheme: DialogThemeData(barrierColor: scrim),

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
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // AppBar Stili
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        titleTextStyle: const TextStyle(
          fontFamily: headingFont,
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
