import 'package:flutter/material.dart';

/// Erişilebilirlik tercihleri (yazı boyutu, yüksek kontrast). Hesap olmadığı için yalnızca bellekte tutulur.
class AppAccessibility extends ChangeNotifier {
  AppAccessibility._();
  static final AppAccessibility instance = AppAccessibility._();

  static const List<double> textScales = [1.0, 1.15, 1.3];

  double _textScale = 1.0;
  bool _highContrast = false;

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
    1.3, 0, 0, 0, -38,
    0, 1.3, 0, 0, -38,
    0, 0, 1.3, 0, -38,
    0, 0, 0, 1, 0,
  ]);
}
