import 'package:flutter/material.dart';
import 'app_logo.dart';

/// Yükleme göstergesi: dönen çarkın yerine Zaman Aynası logosu yavaşça döner ve nefes alır.
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
    duration: const Duration(milliseconds: 1800),
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
            final t = Curves.easeInOut.transform(_c.value);
            final pulse = 0.92 + 0.08 * (1 - (2 * _c.value - 1).abs());
            return Transform.scale(
              scale: pulse,
              child: Transform.rotate(angle: t * 2 * 3.1415926, child: child),
            );
          },
          child: ExcludeSemantics(child: AppLogo(size: widget.size)),
        ),
      ),
    );
  }
}
