import 'package:flutter/material.dart';
import 'dark_cancel.dart';

/// Eser kartlarının ortak şekli: iki çapraz köşe büyük ve akıcı, diğer iki çapraz köşe sivri
/// (sol üst ve sağ alt), görselin etrafında ince bir çerçeve (aralarında küçük bir boşluk).
class SquircleFrame extends StatelessWidget {
  final Widget child;

  /// Büyük (yuvarlak) köşelerin yarıçapı: sağ üst ve sol alt.
  final double radius;

  /// Sivri köşelerin yarıçapı: sol üst ve sağ alt.
  final double sharp;
  final double gap;
  final Color? borderColor;

  /// Altında yumuşak bir gölge (kartlar için).
  final bool elevated;

  const SquircleFrame({
    super.key,
    required this.child,
    this.radius = 40,
    this.sharp = 8,
    this.gap = 4,
    this.borderColor,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius shape(double d) => BorderRadius.only(
      topLeft: Radius.circular((sharp - d).clamp(2, 100)),
      bottomRight: Radius.circular((sharp - d).clamp(2, 100)),
      topRight: Radius.circular(radius - d),
      bottomLeft: Radius.circular(radius - d),
    );
    final inner = ContinuousRectangleBorder(borderRadius: shape(gap));
    return DecoratedBox(
      decoration: ShapeDecoration(
        shadows: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
        shape: ContinuousRectangleBorder(
          borderRadius: shape(0),
          side: BorderSide(
            color: borderColor ?? bordeauxOf(context, alpha: 0.45),
            width: 1.1,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: inner),
          child: child,
        ),
      ),
    );
  }
}
