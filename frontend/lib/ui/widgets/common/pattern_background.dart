import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Çini desenli zemin. Desen, tek renkli (beyaz + saydamlık) `pattern_tile.png` parçasının
/// istenen renge boyanıp döşenmesiyle çizilir; böylece krem ve petrol zeminde aynı dosya kullanılır.
class PatternBackground extends StatelessWidget {
  static const String asset = 'assets/images/pattern_tile.png';

  final Widget child;
  final Color color;
  final Color lineColor;
  final double lineOpacity;

  /// Büyüdükçe desen küçülür (parça genişliği ≈ 484 / [scale] mantıksal piksel).
  final double scale;

  const PatternBackground({
    super.key,
    required this.child,
    this.color = AppColors.bgCanvas,
    this.lineColor = const Color(0xFF7A9296),
    this.lineOpacity = 0.08,
    this.scale = 3.2,
  });

  /// Petrol zeminde (splash) kullanılan açık çizgili hâli.
  const PatternBackground.onDark({super.key, required this.child})
    : color = AppColors.heroPetrol,
      lineColor = const Color(0xFF9CCBD2),
      lineOpacity = 0.17,
      scale = 3.0;

  /// Petrol zeminde çini desenli dekorasyon (Ana Sayfa hero'su gibi özel kapsayıcılar için).
  static BoxDecoration onDarkDecoration({double lineOpacity = 0.17}) =>
      BoxDecoration(
        color: AppColors.heroPetrol,
        image: DecorationImage(
          image: const AssetImage(asset),
          repeat: ImageRepeat.repeat,
          alignment: Alignment.topLeft,
          scale: 3.0,
          colorFilter: ColorFilter.mode(
            const Color(0xFF9CCBD2).withValues(alpha: lineOpacity),
            BlendMode.srcIn,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        image: DecorationImage(
          image: const AssetImage(asset),
          repeat: ImageRepeat.repeat,
          alignment: Alignment.topLeft,
          scale: scale,
          colorFilter: ColorFilter.mode(
            lineColor.withValues(alpha: lineOpacity),
            BlendMode.srcIn,
          ),
        ),
      ),
      child: child,
    );
  }
}
