import 'package:flutter/material.dart';
import '../../../core/state/app_accessibility.dart';

/// Koyu modda uygulamanın genel renk tersine çevirmesini bu alt ağaç için geri alır:
/// fotoğraf, video, kamera, logo ve fotoğraf üstü yazılar gibi özgün kalması gerekenler için.
/// İç içe kullanılırsa yalnızca en dıştaki etkili olur (iki kez çevirmemek için).
class DarkCancel extends StatelessWidget {
  final Widget child;
  const DarkCancel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (_Cancelled.of(context)) return child;
    return ListenableBuilder(
      listenable: AppAccessibility.instance,
      builder: (context, _) {
        if (!AppAccessibility.instance.isDark(context)) return child;
        return _Cancelled(
          child: ColorFiltered(
            colorFilter: AppAccessibility.darkFilter,
            child: child,
          ),
        );
      },
    );
  }
}

class _Cancelled extends InheritedWidget {
  const _Cancelled({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Cancelled>() != null;

  @override
  bool updateShouldNotify(_Cancelled old) => false;
}
