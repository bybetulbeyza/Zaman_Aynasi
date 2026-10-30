import 'package:flutter/material.dart';
import 'app_strings.dart';

/// Uygulama genelinde tek dil durumu. TR | EN geçişi hangi ekrandan yapılırsa yapılsın hepsini günceller.
class AppLang extends ChangeNotifier {
  AppLang._();
  static final AppLang instance = AppLang._();

  bool _isEnglish = false;
  bool get isEnglish => _isEnglish;

  void setEnglish(bool value) {
    if (value == _isEnglish) return;
    _isEnglish = value;
    notifyListeners();
  }
}

/// `context.t('anahtar')` / `context.isEn` kullanan widget'lar dil değişince kendiliğinden yenilenir.
class AppLangScope extends InheritedNotifier<AppLang> {
  const AppLangScope({super.key, required AppLang lang, required super.child})
      : super(notifier: lang);
}

extension AppLangContext on BuildContext {
  bool get isEn {
    final scope = dependOnInheritedWidgetOfExactType<AppLangScope>();
    return (scope?.notifier ?? AppLang.instance).isEnglish;
  }

  /// Arayüz metni. İngilizce karşılığı yoksa Türkçeye döner.
  String t(String key) {
    final table = isEn ? appStringsEn : appStringsTr;
    return table[key] ?? appStringsTr[key] ?? key;
  }
}
