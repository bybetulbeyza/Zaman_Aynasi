import 'dark_cancel.dart';
import 'package:flutter/material.dart';

/// Eser kartlarının ortak şekli: iki çapraz köşe büyük ve akıcı, diğer iki çapraz köşe sivri
/// (sol üst ve sağ alt). Dış çerçeve yoktur; görsel kartın tamamını kaplar, kenarın hemen içinde
/// ince, yarı saydam bir "ışık kenarı" ve altında yumuşak bir gölge bulunur.
class SquircleFrame extends StatelessWidget {
  final Widget child;

  /// Büyük (yuvarlak) köşelerin yarıçapı: sağ üst ve sol alt.
  final double radius;

  /// Sivri köşelerin yarıçapı: sol üst ve sağ alt.
  final double sharp;

  /// Eski çerçeve boşluğu; artık kullanılmaz (çağıran kodlar bozulmasın diye durur).
  final double gap;

  /// Eski çerçeve rengi; artık kullanılmaz.
  final Color? borderColor;

  /// Altında yumuşak bir gölge.
  final bool elevated;

  /// Kenarın içindeki ince ışık çizgisinin rengi.
  final Color? rimColor;

  const SquircleFrame({
    super.key,
    required this.child,
    this.radius = 40,
    this.sharp = 8,
    this.gap = 0,
    this.borderColor,
    this.elevated = true,
    this.rimColor,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.only(
      topLeft: Radius.circular(sharp),
      bottomRight: Radius.circular(sharp),
      topRight: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );
    final shape = ContinuousRectangleBorder(borderRadius: border);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: elevated
            ? [
                BoxShadow(
                  color: shadowOf(context, 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: ShapeDecoration(
            shape: ContinuousRectangleBorder(
              borderRadius: border,
              side: BorderSide(
                color: rimColor ?? Colors.white.withValues(alpha: 0.5),
                width: 1.4,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
