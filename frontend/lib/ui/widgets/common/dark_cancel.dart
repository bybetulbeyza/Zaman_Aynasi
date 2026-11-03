import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/state/app_accessibility.dart';

/// Alt ağaç şu an koyu mod renk tersine çevirmesinden geçiyor mu? (Kökte main.dart belirler;
/// [DarkCancel] alt ağaç için false, [DarkReapply] true yapar.)
class DarkScope extends InheritedWidget {
  final bool inverted;
  const DarkScope({super.key, required this.inverted, required super.child});

  static bool invertedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DarkScope>()?.inverted ??
      false;

  @override
  bool updateShouldNotify(DarkScope old) => old.inverted != inverted;
}

/// Koyu modda vurgu olarak görünecek yumuşak gül rengi ve sayfa zemini; filtreden sonra bu renkler
/// görünsün diye önceden hesaplanmış (filtreye girmeden önceki) karşılıkları kullanılır.
final Color _bordeauxPreImage = AppAccessibility.darkPre(
  const Color(0xFFE5808F),
);
final Color _canvasPreImage = AppAccessibility.darkPre(const Color(0xFF16272E));

Color bordeauxOf(BuildContext context, {double alpha = 1}) {
  final c = DarkScope.invertedOf(context)
      ? _bordeauxPreImage
      : AppColors.ciniBordeaux;
  return alpha == 1 ? c : c.withValues(alpha: alpha);
}

/// Gölge rengi: koyu modda filtre siyahı beyaza çevirip "parlama" yaptığı için, filtreden sonra
/// koyu gölge görünsün diye açık bir ön renk kullanılır (etkisi zayıf kalmasın diye biraz güçlendirilir).
Color shadowOf(BuildContext context, double alpha) =>
    DarkScope.invertedOf(context)
    ? Colors.white.withValues(alpha: (alpha * 3).clamp(0.0, 0.9))
    : Colors.black.withValues(alpha: alpha);

/// Sayfa zemini: açıkta sıcak krem, koyuda derin petrol (kartlardan bir ton açık).
Color canvasOf(BuildContext context) =>
    DarkScope.invertedOf(context) ? _canvasPreImage : AppColors.bgCanvas;

/// Koyu modda uygulamanın genel renk tersine çevirmesini bu alt ağaç için geri alır:
/// fotoğraf, video, kamera, logo ve fotoğraf üstü yazılar gibi özgün kalması gerekenler için.
/// İç içe kullanılırsa yalnızca en dıştaki etkili olur (iki kez çevirmemek için).
class DarkCancel extends StatelessWidget {
  final Widget child;
  const DarkCancel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!DarkScope.invertedOf(context)) return child;
    return DarkScope(
      inverted: false,
      child: ColorFiltered(
        colorFilter: AppAccessibility.darkFilter,
        child: child,
      ),
    );
  }
}

/// [DarkCancel] ile özgün tutulan bir alanın içinde, bir parçayı yine koyu temaya sokar
/// (örn. koyu zemini korunan ana sayfa başlığındaki arama çubuğu).
class DarkReapply extends StatelessWidget {
  final Widget child;
  const DarkReapply({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppAccessibility.instance,
      builder: (context, _) {
        final dark = AppAccessibility.instance.isDark(context);
        if (!dark || DarkScope.invertedOf(context)) return child;
        return DarkScope(
          inverted: true,
          child: ColorFiltered(
            colorFilter: AppAccessibility.darkFilter,
            child: child,
          ),
        );
      },
    );
  }
}
