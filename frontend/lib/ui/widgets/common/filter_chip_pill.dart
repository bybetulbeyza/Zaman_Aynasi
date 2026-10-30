import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'app_icon.dart';

/// Tasarımdaki hap şeklinde filtre çipi: seçiliyken dolu ([accent] ya da teal), değilken beyaz.
/// [icon] verilirse etiketin başında özel ikon gösterilir (kategori çipleri için).
class FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? icon;
  final Color? accent;

  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final base = accent ?? AppColors.primaryTeal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: icon == null ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? base : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? base
                : (accent ?? AppColors.chipBorder).withValues(
                    alpha: accent == null ? 1 : 0.45,
                  ),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: 20, color: selected ? Colors.white : base),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
