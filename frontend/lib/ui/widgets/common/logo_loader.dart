import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_logo.dart';

/// Yükleme göstergesi: Zaman Aynası logosu hafifçe nefes alır ve üzerinden bir ışık süzülür
/// (bir aynanın parıltısı gibi); dönen çark yok.
class LogoLoader extends StatefulWidget {
  final double size;
  const LogoLoader({super.key, this.size = 56});

  @override
  State<LogoLoader> createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Yükleniyor',
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final t = _c.value;
            // Nefes: 0.94 ↔ 1.0
            final breathe =
                0.94 + 0.06 * (0.5 - 0.5 * math.cos(t * 2 * math.pi));
            return Transform.scale(
              scale: breathe,
              child: ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) => LinearGradient(
                  begin: const Alignment(-1, -0.6),
                  end: const Alignment(1, 0.6),
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.7),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0.4, 0.5, 0.6],
                  transform: _Sweep(t * 2.4 - 1.2),
                ).createShader(rect),
                child: child,
              ),
            );
          },
          child: ExcludeSemantics(child: AppLogo(size: widget.size)),
        ),
      ),
    );
  }
}

class _Sweep extends GradientTransform {
  final double percent;
  const _Sweep(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}
