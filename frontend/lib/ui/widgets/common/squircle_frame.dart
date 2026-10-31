import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Eser kartlarının ortak şekli: iOS ikonları gibi akıcı "squircle" köşeler ve görselin
/// etrafında ince bir çerçeve (çerçeve ile görsel arasında küçük bir boşluk).
class SquircleFrame extends StatelessWidget {
  final Widget child;
  final double radius;
  final double gap;
  final Color? borderColor;

  const SquircleFrame({
    super.key,
    required this.child,
    this.radius = 40,
    this.gap = 4,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final inner = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(radius - gap),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color:
                borderColor ?? AppColors.ciniBordeaux.withValues(alpha: 0.45),
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
