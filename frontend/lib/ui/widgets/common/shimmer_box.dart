import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Yüklenen içeriğin yerinde duran, üzerinden yumuşak bir ışık süzülen iskelet yüzey.
/// Boyutunu ebeveyninden alır; köşeleri ebeveyn kırpar (ör. SquircleFrame / ClipRRect).
class ShimmerBox extends StatefulWidget {
  final BorderRadius? borderRadius;
  const ShimmerBox({super.key, this.borderRadius});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          gradient: LinearGradient(
            begin: const Alignment(-1, -0.3),
            end: const Alignment(1, 0.3),
            colors: const [
              AppColors.borderSubtle,
              Color(0xFFF6F2EA),
              AppColors.borderSubtle,
            ],
            stops: const [0.35, 0.5, 0.65],
            transform: _Slide(_c.value * 2 - 1),
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Slide extends GradientTransform {
  final double percent; // -1 → 1: ışık soldan sağa geçer
  const _Slide(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}
