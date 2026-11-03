import '../common/dark_cancel.dart';
import '../common/pill_button.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/category_style.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_icon.dart';

/// Kategori renginde, çift halkalı mühür. [earned] false ise silik, boş bir yuva çizer.
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

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(place.category);
    final color = earned ? style.color : const Color(0xFF9C978C);
    // Her mühür biraz farklı eğimde basılır
    final tilt = (((int.tryParse(place.id) ?? 0) * 37) % 11 - 5) * 0.025;
    final icon = style.icon.replaceFirst('pin_', 'cat_');
    return Transform.rotate(
      angle: earned ? tilt : 0,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _StampPainter(color: color, earned: earned),
          child: Center(
            child: AppIcon(icon, size: size * 0.42, color: color),
          ),
        ),
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  final Color color;
  final bool earned;
  _StampPainter({required this.color, required this.earned});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final ink = color.withValues(alpha: earned ? 0.92 : 0.85);

    if (earned) {
      canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.07));
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = earned ? 3.2 : 2,
    );

    // İç halka: yazılı mührü andıran kesikli çizgi
    final inner = r - 7;
    final dash = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = earned ? 1.6 : 1.2;
    const count = 36;
    for (var i = 0; i < count; i++) {
      final a = (i / count) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: inner),
        a,
        math.pi * 2 / count * 0.55,
        false,
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(_StampPainter old) =>
      old.color != color || old.earned != earned;
}

/// Mühür kazanılınca ekranın üstüne düşen kutlama.
Future<void> showStampCeremony(
  BuildContext context,
  HeritagePlace place, {
  VoidCallback? onOpenPassport,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
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
