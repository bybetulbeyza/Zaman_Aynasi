import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_network_image.dart';
import '../common/dark_cancel.dart';
import '../common/squircle_frame.dart';
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
        child: SquircleFrame(
          radius: 40,
          // Geniş ekranlarda (tablet) kart ekranı doldurmasın
          child: LayoutBuilder(
            builder: (context, box) => SizedBox(
              width: box.maxWidth,
              height: (box.maxWidth / 1.3).clamp(0.0, 330.0),
              child: DarkCancel(child: _compare(p, en)),
            ),
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
                // Alttaki ad yazısı okunsun diye koyu bir geçiş
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.5, 1.0],
                        colors: [Colors.transparent, Color(0xCC0F2F3A)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.nameFor(en),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: 22,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.category.labelFor(en),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Opacity(
                    opacity: d > 0.3 ? 1 : 0,
                    child: GlassBadge(
                      context.t('period_label'),
                      tint: AppColors.primaryTealDark,
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 16,
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
