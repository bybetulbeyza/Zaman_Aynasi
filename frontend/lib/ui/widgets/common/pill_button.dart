import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'dark_cancel.dart';

/// Uygulamanın ortak düğmesi: açık bordo zemin, ince bordo çerçeve ve bordo yazı
/// (eser kartlarındaki "Eseri keşfet" rozetiyle aynı dil). [color] verilirse vurgu rengi o olur.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final Color? color;

  const PillButton(this.label, {super.key, this.onPressed, this.color})
    : outlined = false;

  const PillButton.outlined(this.label, {super.key, this.onPressed, this.color})
    : outlined = true;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? bordeauxOf(context);
    final fill = outlined ? Colors.white : AppColors.ciniBordeauxLight;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        backgroundColor: fill,
        side: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
