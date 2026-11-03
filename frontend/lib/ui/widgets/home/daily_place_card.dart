import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_network_image.dart';
import '../common/dark_cancel.dart';
import '../slider/slider_parts.dart';

/// Ana ekranda "Günün eseri": tarihî ve günümüz fotoğrafı kendiliğinden kayan mini karşılaştırma.
class DailyPlaceCard extends StatefulWidget {
  final HeritagePlace place;
  final VoidCallback onTap;
  const DailyPlaceCard({super.key, required this.place, required this.onTap});

  @override
  State<DailyPlaceCard> createState() => _DailyPlaceCardState();
}

class _DailyPlaceCardState extends State<DailyPlaceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat(reverse: true);
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeInOutCubic,
  );

  @override
  void dispose() {
    _c.dispose();
    return super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.place;
    final en = context.isEn;
    return Semantics(
      button: true,
      label: '${context.t('daily_title')}: ${p.nameFor(en)}',
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.chipBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: DarkCancel(child: _compare(p, en)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nameFor(en),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.descriptionFor(en),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primaryTeal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compare(HeritagePlace p, bool en) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        return AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final d = 0.18 + 0.64 * _t.value;
            final x = d * w;
            return Stack(
              fit: StackFit.expand,
              children: [
                // sağ: günümüz, sol: tarihî (eser sayfasındaki slider ile aynı)
                AppNetworkImage(imageUrl: p.imageAfterUrl, fit: BoxFit.cover),
                ClipRect(
                  clipper: _LeftClip(d),
                  child: AppNetworkImage(
                    imageUrl: p.imageBeforeUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: x - 1.25,
                  top: 0,
                  bottom: 0,
                  child: const GlassDividerLine(),
                ),
                Positioned(
                  left: x - 28,
                  top: h / 2 - 28,
                  child: const IgnorePointer(child: GlassKnob()),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: GlassBadge(
                    context.t('daily_title'),
                    tint: AppColors.primaryTealDark,
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Opacity(
                    opacity: d > 0.3 ? 1 : 0,
                    child: GlassBadge(
                      context.t('period_label'),
                      tint: AppColors.primaryTealDark,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Opacity(
                    opacity: d < 0.7 ? 1 : 0,
                    child: GlassBadge(
                      context.t('today_label'),
                      tint: AppColors.ciniCobalt,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LeftClip extends CustomClipper<Rect> {
  final double f;
  _LeftClip(this.f);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * f, size.height);

  @override
  bool shouldReclip(_LeftClip old) => old.f != f;
}
