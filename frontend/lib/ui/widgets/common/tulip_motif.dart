import 'package:flutter/material.dart';

/// Lale motifi. Logo hazır olunca sadece assets/images/tulip_motif.png değişir.
class TulipMotif extends StatelessWidget {
  final double height;
  const TulipMotif({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/tulip_motif.png', height: height);
  }
}
