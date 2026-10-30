import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Uygulamanın özel (çini esinli) vektör ikonları. Beyaz çizgi olarak saklanır, rengi koddan verilir.
/// Adlar assets/icons/ altındaki dosya adlarıdır (örn. 'home', 'pin_han').
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const AppIcon(this.name, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? IconTheme.of(context).color ?? Colors.black,
        BlendMode.srcIn,
      ),
    );
  }
}
