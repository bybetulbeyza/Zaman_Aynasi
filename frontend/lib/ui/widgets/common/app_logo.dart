import 'package:flutter/material.dart';

/// Zaman Aynası logosu (yuvarlak, kendi lacivert halkası olan çini lale amblemi).
/// Logo değişirse yalnızca assets/images/app_logo.png değiştirilir.
class AppLogo extends StatelessWidget {
  static const String asset = 'assets/images/app_logo.png';

  final double size;

  /// Koyu zeminlerde logonun etrafına hafif bir gölge verir.
  final bool shadow;

  const AppLogo({super.key, this.size = 80, this.shadow = false});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Zaman Aynası',
    );
    if (!shadow) return image;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: image,
    );
  }
}
