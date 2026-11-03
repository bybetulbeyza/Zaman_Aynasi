import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'app_card.dart';
import 'dark_cancel.dart';

/// Uygulamadaki küçük "dokunulabilir satır" kartı: beyaz zemin, ortak köşe şekli, ince bordo çerçeve,
/// solda isteğe bağlı simge/görsel, ortada başlık (+alt yazı), sağda rozet ya da bordo ok.
/// Seçili olduğunda çerçeve koyulaşır ve sağda bir onay işareti çıkar.
class ActionCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsets padding;
  final double round;
  final bool shadow;

  /// Henüz kullanılamayan öğe: silik ve nötr çerçeveli görünür.
  final bool dimmed;

  const ActionCard({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.round = 24,
    this.shadow = false,
    this.dimmed = false,
  });

  /// Bordo vurgulu küçük yuvarlak simge (solda kullanılır).
  static Widget iconBubble(
    BuildContext context,
    IconData icon, {
    bool filled = false,
  }) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: filled ? bordeauxOf(context) : AppColors.ciniBordeauxLight,
      shape: BoxShape.circle,
    ),
    child: Icon(
      icon,
      size: 21,
      color: filled ? Colors.white : bordeauxOf(context),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final accent = bordeauxOf(context);
    final shape = appCardBorder(
      round: round,
      side: dimmed
          ? AppColors.chipBorder
          : (selected ? accent : accent.withValues(alpha: 0.4)),
      width: selected ? 1.6 : 1.2,
    );
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Semantics(
        button: onTap != null,
        selected: selected,
        label: subtitle == null ? title : '$title, $subtitle',
        excludeSemantics: true,
        onTap: onTap,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape,
            color: Colors.white,
            shadows: shadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: shape,
              child: Padding(
                padding: padding,
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    trailing ??
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded,
                          color: accent,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
