import '../common/dark_cancel.dart';
import '../common/pill_button.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/category_style.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_icon.dart';
import '../../../data/repositories/heritage_repository.dart';
import '../share/share_cards.dart';

/// Esere özel mühür: ortada eserin kendi fotoğrafı mürekkep baskısı gibi (kategori renginde),
/// halkada adı ve "BURSA · yapım yılı". [earned] false ise silik, gri bir yuva çizer.
class StampWidget extends StatelessWidget {
  final HeritagePlace place;
  final bool earned;
  final double size;

  const StampWidget({
    super.key,
    required this.place,
    required this.earned,
    this.size = 96,
  });

  /// Fotoğrafı mühür için küçük, kare ve gri tonlu ister (Cloudinary dönüşümü).
  static String? inkPhotoUrl(HeritagePlace p) {
    final url = p.imageAfterUrl.trim();
    const marker = '/image/upload/';
    if (!url.contains(marker)) return null;
    return url.replaceFirst(
      marker,
      '$marker'
      'c_fill,g_auto,w_320,h_320,e_grayscale/e_contrast:40/',
    );
  }

  static String _year(String raw) =>
      RegExp(r'\d{3,4}').firstMatch(raw)?.group(0) ?? '';

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(place.category);
    final color = earned ? style.color : const Color(0xFF9C978C);
    // Her mühür biraz farklı eğimde basılır
    final tilt = (((int.tryParse(place.id) ?? 0) * 37) % 11 - 5) * 0.025;
    final en = context.isEn;
    final year = _year(place.constructionDate);
    final bottom = year.isEmpty ? 'BURSA' : 'BURSA · $year';
    final photo = inkPhotoUrl(place);
    final photoR = size * 0.29;
    return Transform.rotate(
      angle: earned ? tilt : 0,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _StampPainter(
            color: color,
            earned: earned,
            top: place.nameFor(en).toUpperCase(),
            bottom: bottom,
            photoR: photoR,
          ),
          child: Center(
            child: SizedBox.square(
              dimension: photoR * 2,
              child: ClipOval(
                child: photo == null
                    ? Center(
                        child: AppIcon(
                          style.icon.replaceFirst('pin_', 'cat_'),
                          size: photoR,
                          color: color,
                        ),
                      )
                    : Opacity(
                        opacity: earned ? 1 : 0.35,
                        child: ColorFiltered(
                          colorFilter: _inkFilter(color),
                          child: CachedNetworkImage(
                            imageUrl: photo,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (_, _) => const SizedBox(),
                            errorWidget: (_, _, _) => Center(
                              child: AppIcon(
                                style.icon.replaceFirst('pin_', 'cat_'),
                                size: photoR,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Koyu yerler mürekkep (mühür rengi), açık yerler şeffaf: kâğıda basılmış görünüm.
  static ColorFilter _inkFilter(Color c) {
    final r = c.r * 255, g = c.g * 255, b = c.b * 255;
    // Parlaklık = 0.299R + 0.587G + 0.114B; alfa = 255 - parlaklık (biraz güçlendirilmiş)
    const k = 1.25;
    return ColorFilter.matrix([
      0, 0, 0, 0, r, //
      0, 0, 0, 0, g, //
      0, 0, 0, 0, b, //
      -0.299 * k, -0.587 * k, -0.114 * k, 0, 255 * k * 0.92,
    ]);
  }
}

class _StampPainter extends CustomPainter {
  final Color color;
  final bool earned;
  final String top;
  final String bottom;
  final double photoR;
  _StampPainter({
    required this.color,
    required this.earned,
    required this.top,
    required this.bottom,
    required this.photoR,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final w = size.width;
    final r = w / 2 - w * 0.02;
    final ink = color.withValues(alpha: earned ? 0.92 : 0.6);

    if (earned) {
      canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.06));
    }
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, r, line..strokeWidth = w * (earned ? 0.03 : 0.018));
    final inner = r - w * 0.04;
    canvas.drawCircle(c, inner, line..strokeWidth = w * 0.01);
    canvas.drawCircle(c, photoR, line..strokeWidth = w * 0.012);

    // Halka yazıları: üstte eserin adı, altta şehir ve yıl
    final mid = (inner + photoR) / 2;
    final band = inner - photoR;
    final topSize =
        (band *
        (top.length > 22
            ? 0.36
            : top.length > 15
            ? 0.42
            : 0.5));
    _arcText(canvas, c, mid, top, topSize, ink, true);
    _arcText(canvas, c, mid, bottom, band * 0.42, ink, false);

    // Yanlarda küçük baklava süsler
    final d = band * 0.12;
    for (final sx in [-1.0, 1.0]) {
      final p = c + Offset(sx * mid, 0);
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - d)
          ..lineTo(p.dx + d * 0.7, p.dy)
          ..lineTo(p.dx, p.dy + d)
          ..lineTo(p.dx - d * 0.7, p.dy)
          ..close(),
        Paint()..color = ink,
      );
    }
  }

  void _arcText(
    Canvas canvas,
    Offset c,
    double radius,
    String text,
    double fontSize,
    Color col,
    bool topSide,
  ) {
    final style = TextStyle(
      fontFamily: 'DMSans',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: col,
    );
    final gap = fontSize * 0.14;
    final glyphs = [
      for (final ch in text.characters)
        TextPainter(
          text: TextSpan(text: ch, style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    final total =
        glyphs.fold<double>(0, (s, g) => s + g.width) +
        gap * (glyphs.length - 1);
    // Yazı yayın en fazla ~%85'ini kaplasın
    final maxArc = math.pi * 0.85 * radius;
    final scale = total > maxArc ? maxArc / total : 1.0;
    var a = topSide
        ? -math.pi / 2 - (total * scale / radius) / 2
        : math.pi / 2 + (total * scale / radius) / 2;
    for (final g in glyphs) {
      final half = g.width * scale / 2 / radius;
      a += topSide ? half : -half;
      canvas.save();
      canvas.translate(
        c.dx + radius * math.cos(a),
        c.dy + radius * math.sin(a),
      );
      canvas.rotate(topSide ? a + math.pi / 2 : a - math.pi / 2);
      canvas.scale(scale);
      g.paint(canvas, Offset(-g.width / 2, -g.height / 2));
      canvas.restore();
      a += topSide
          ? half + gap * scale / radius
          : -(half + gap * scale / radius);
    }
  }

  @override
  bool shouldRepaint(_StampPainter old) =>
      old.color != color ||
      old.earned != earned ||
      old.top != top ||
      old.bottom != bottom ||
      old.photoR != photoR;
}

/// Mühür kazanılınca ekranın üstüne düşen kutlama.
Future<void> showStampCeremony(
  BuildContext context,
  HeritagePlace place, {
  VoidCallback? onOpenPassport,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: scrimOf(context, 0.55),
    builder: (ctx) =>
        _CeremonyDialog(place: place, onOpenPassport: onOpenPassport),
  );
}

class _CeremonyDialog extends StatefulWidget {
  final HeritagePlace place;
  final VoidCallback? onOpenPassport;
  const _CeremonyDialog({required this.place, this.onOpenPassport});

  @override
  State<_CeremonyDialog> createState() => _CeremonyDialogState();
}

class _CeremonyDialogState extends State<_CeremonyDialog> {
  @override
  void initState() {
    super.initState();
    // Mühür kâğıda değdiği anda titreşim
    Future.delayed(
      const Duration(milliseconds: 380),
      HapticFeedback.heavyImpact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final en = context.isEn;
    return Dialog(
      backgroundColor: canvasOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              builder: (_, t, child) => Opacity(
                opacity: (t * 2.5).clamp(0.0, 1.0),
                child: Transform.scale(scale: 1 + (1 - t) * 1.3, child: child),
              ),
              child: StampWidget(place: widget.place, earned: true, size: 150),
            ),
            const SizedBox(height: 22),
            Text(
              context.t('stamp_earned'),
              style: const TextStyle(
                fontFamily: AppTheme.headingFont,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.place.nameFor(en),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: PillButton(
                context.t('share_btn'),
                onPressed: () async {
                  final places = await HeritageRepository().getPlacesCached();
                  if (!context.mounted) return;
                  showShareCard(
                    context,
                    card: StampShareCard(
                      place: widget.place,
                      total: places.length,
                    ),
                    text: context
                        .t('share_stamp_text')
                        .replaceAll('{name}', widget.place.nameFor(en)),
                    fileName: 'muhur_${widget.place.id}',
                    kind: 'stamp',
                    placeId: widget.place.id,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: PillButton.outlined(
                context.t('stamp_open'),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onOpenPassport?.call();
                },
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.t('ok_btn'),
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
