import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Lale motifi. Logo hazır olunca sadece assets/images/tulip_motif.png değişir.
class TulipMotif extends StatelessWidget {
  final double height;
  const TulipMotif({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/tulip_motif.png', height: height);
  }
}

/// Kart köşesindeki krem zeminli küçük lale rozeti.
class TulipBadge extends StatelessWidget {
  const TulipBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 40,
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
      ),
      child: const TulipMotif(height: 30),
    );
  }
}
