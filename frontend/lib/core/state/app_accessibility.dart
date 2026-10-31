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

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _readGuide = p.getBool('read_guide') ?? false;
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
