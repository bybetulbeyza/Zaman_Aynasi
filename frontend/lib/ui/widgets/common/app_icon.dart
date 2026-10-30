import 'package:flutter/material.dart';

/// Uygulamanın özel (çini esinli) çizgi ikonları. Beyaz maske olarak saklanır, rengi koddan verilir.
/// Adlar assets/icons/ altındaki dosya adlarıdır (örn. 'home', 'cat_han').
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const AppIcon(this.name, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/$name.png',
      width: size,
      height: size,
      color: color ?? IconTheme.of(context).color,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
    );
  }
}
