import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';

/// Başlık + altında kısa bordo çizgi; sağda opsiyonel "Tümü" bağlantısı.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.titleMedium),
            const SizedBox(height: 4),
            Container(width: 28, height: 2.5, color: AppColors.ciniBordeaux),
          ],
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
