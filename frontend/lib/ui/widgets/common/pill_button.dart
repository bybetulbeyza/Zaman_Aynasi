import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Tasarımdaki hap butonlar: dolu teal ([PillButton]) ve çerçeveli ([PillButton.outlined]).
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
    final base = color ?? AppColors.primaryTeal;
    final shape = const StadiumBorder();
    const pad = EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);

    return outlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: base,
              backgroundColor: Colors.white,
              side: BorderSide(color: base, width: 1.2),
              padding: pad,
              shape: shape,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: text,
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: base,
              foregroundColor: Colors.white,
              padding: pad,
              shape: shape,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: text,
          );
  }
}
