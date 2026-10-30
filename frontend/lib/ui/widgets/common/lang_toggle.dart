import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// TR | EN geçişi. [onDark] true ise petrol zemin üstünde (hero) çizgi beyaz olur.
class LangToggle extends StatelessWidget {
  final bool isTurkish;
  final ValueChanged<bool> onChanged;
  final bool onDark;

  const LangToggle({
    super.key,
    required this.isTurkish,
    required this.onChanged,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = onDark ? Colors.white : AppColors.primaryTeal;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('TR', isTurkish, accent),
          _seg('EN', !isTurkish, accent),
        ],
      ),
    );
  }

  Widget _seg(String label, bool selected, Color accent) {
    final selBg = onDark ? Colors.white : AppColors.primaryTeal;
    final selFg = onDark ? AppColors.heroPetrol : Colors.white;
    return GestureDetector(
      onTap: () => onChanged(label == 'TR'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? selBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? selFg : accent,
          ),
        ),
      ),
    );
  }
}
