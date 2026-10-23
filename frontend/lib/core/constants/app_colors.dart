import 'package:flutter/material.dart';

class AppColors {
  // --- Ana Karakter Renkleri ---

  // Zümrüt Yeşili / Koyu Petrol (Primary - Butonlar, Seçili Filtreler, Rota Çizgisi, Aktif Sekmeler)
  static const Color primaryTeal = Color(0xFF0F6B5C);
  static const Color primaryTealDark = Color(0xFF0A4F44);
  static const Color primaryTealLight = Color(0xFFE6F2F0);

  // Çini Bordosu (Burgundy - Floating QR Butonu, Audio Play, AI Butonları, İnce Çerçeveler)
  static const Color ciniBordeaux = Color(0xFF7A1C28);
  static const Color ciniBordeauxDark = Color(0xFF5E131E);
  static const Color ciniBordeauxLight = Color(0xFFF9ECEE);

  // Kobalt Çini Mavisi (İkincil Vurgular, Dönem Karşılaştırma Etiketleri)
  static const Color ciniCobalt = Color(0xFF1E3A8A);

  // --- Zemin ve Kart Tonları ---

  // Zemin Rengi (Ham Çini / Kağıt Dokulu Sıcak Kırık Beyaz)
  static const Color bgCanvas = Color(0xFFF9F6F0);

  // Kartlar ve Modal Yüzeyleri (Saf Beyaz)
  static const Color cardBg = Colors.white;

  // Pasif Filtre Hapları (Chips) ve İkincil Zeminler
  static const Color chipInactiveBg = Colors.white;
  static const Color chipBorder = Color(0xFFE5DFD5);

  // Arama çubuğunun ince bordo konturu
  static const Color inputBorderBordeaux = Color(0xFF8B2635);

  // --- Tipografi ve Çizgiler ---

  static const Color textDark = Color(0xFF1C1A17);       // Başlıklar ve Eser İsimleri
  static const Color textMuted = Color(0xFF706B63);      // Açıklama, Mesafe ve İkincil Metinler
  static const Color borderSubtle = Color(0xFFE8E3DA);   // Ayırıcı İnce Çizgiler
  static const Color dividerLine = Color(0xFF7A1C28);    // Alt Navigation Bar üstündeki ince bordo hat
}