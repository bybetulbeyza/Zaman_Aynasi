import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Erişilebilirlik tercihleri (yazı boyutu, yüksek kontrast). Hesap olmadığı için yalnızca bellekte tutulur.
class AppAccessibility extends ChangeNotifier {
  AppAccessibility._();
  static final AppAccessibility instance = AppAccessibility._();

  static const List<double> textScales = [1.0, 1.15, 1.3];

  double _textScale = 1.0;
  bool _highContrast = false;

  /// Sesli rehber yerine yazılı metni göstermek (işitme engelliler için); seçim hatırlanır.
  bool _readGuide = false;
  bool get readGuide => _readGuide;

  /// Görünüm: 0 = sistemi izle, 1 = açık, 2 = koyu. Seçim hatırlanır.
  int _themeMode = 0;
  int get themeMode => _themeMode;

  /// Koyu mod şu an etkin mi? (Sistemi izliyorsa cihazın tercihine bakar.)
  bool isDark(BuildContext context) =>
      _themeMode == 2 ||
      (_themeMode == 0 &&
          MediaQuery.platformBrightnessOf(context) == Brightness.dark);

  Future<void> setThemeMode(int value) async {
    if (value == _themeMode) return;
    _themeMode = value;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('theme_mode', value);
    } catch (_) {}
  }

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _readGuide = p.getBool('read_guide') ?? false;
      _themeMode = p.getInt('theme_mode') ?? 0;
    } catch (_) {}
  }

  Future<void> setReadGuide(bool value) async {
    if (value == _readGuide) return;
    _readGuide = value;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('read_guide', value);
    } catch (_) {}
  }

  double get textScale => _textScale;
  bool get highContrast => _highContrast;

  void setTextScale(double value) {
    if (value == _textScale) return;
    _textScale = value;
    notifyListeners();
  }

  void setHighContrast(bool value) {
    if (value == _highContrast) return;
    _highContrast = value;
    notifyListeners();
  }

  /// Koyu mod: arayüz renklerini "akıllı tersine çevirir" (açık ↔ koyu, ton korunur).
  /// Matris kendi tersidir; fotoğraf, video ve harita pinleri aynı filtreyle tekrar çevrilince
  /// (bkz. DarkCancel) özgün renklerine döner.
  static const ColorFilter darkFilter = ColorFilter.matrix(<double>[
    0.574, -1.430, -0.144, 0, 255, //
    -0.426, -0.430, -0.144, 0, 255, //
    -0.426, -1.430, 0.856, 0, 255, //
    0, 0, 0, 1, 0,
  ]);

  /// Kontrastı artıran renk matrisi (yalnızca yüksek kontrast açıkken kullanılır).
  static const ColorFilter contrastFilter = ColorFilter.matrix(<double>[
    1.3,
    0,
    0,
    0,
    -38,
    0,
    1.3,
    0,
    0,
    -38,
    0,
    0,
    1.3,
    0,
    -38,
    0,
    0,
    0,
    1,
    0,
  ]);
}
