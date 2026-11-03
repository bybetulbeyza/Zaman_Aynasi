import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Sesli rehber kartı: yumuşak teal zemin, çerçeve, yuvarlak oynat düğmesi ve ses dalgası.
/// Hem kayıtlı ses hem cihaz sesli okuması aynı görünümü kullanır.
class GuideCard extends StatefulWidget {
  final bool playing;
  final VoidCallback? onTap;
  final String title;
  final Widget bottom;
  final String? trailing;
  final bool dimmed;

  /// Daha küçük düğme ve dolgu (ör. tur kartı).
  final bool compact;

  /// Çalarken düğmede gösterilecek simge (varsayılan: duraklat).
  final IconData activeIcon;

  /// Çalmıyorken düğmede gösterilecek simge (varsayılan: oynat).
  final IconData idleIcon;

  const GuideCard({
    super.key,
    required this.playing,
    required this.onTap,
    required this.title,
    required this.bottom,
    this.trailing,
    this.dimmed = false,
    this.compact = false,
    this.activeIcon = Icons.pause_rounded,
    this.idleIcon = Icons.play_arrow_rounded,
  });

  @override
  State<GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<GuideCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didUpdateWidget(GuideCard old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.playing && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.playing) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.dimmed ? 0.6 : 1,
      child: Container(
        padding: widget.compact
            ? const EdgeInsets.fromLTRB(10, 9, 16, 9)
            : const EdgeInsets.fromLTRB(12, 12, 18, 12),
        decoration: ShapeDecoration(
          color: AppColors.primaryTealLight,
          shape: ContinuousRectangleBorder(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
              topRight: Radius.circular(44),
              bottomLeft: Radius.circular(44),
            ),
            side: BorderSide(
              color: AppColors.primaryTeal.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onTap,
              child: SizedBox(
                width: widget.compact ? 46 : 62,
                height: widget.compact ? 46 : 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Transform.scale(
                        scale: 1 + 0.28 * _pulse.value,
                        child: Container(
                          width: widget.compact ? 40 : 54,
                          height: widget.compact ? 40 : 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryTeal.withValues(
                                alpha: widget.playing
                                    ? 0.35 * (1 - _pulse.value)
                                    : 0,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: widget.compact ? 38 : 52,
                      height: widget.compact ? 38 : 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryTeal,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.playing ? widget.activeIcon : widget.idleIcon,
                        color: Colors.white,
                        size: widget.compact ? 24 : 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: AppColors.primaryTealDark,
                      fontWeight: FontWeight.w800,
                      fontSize: widget.compact ? 15 : 16.5,
                    ),
                  ),
                  SizedBox(height: widget.compact ? 5 : 6),
                  widget.bottom,
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 10),
              Text(
                widget.trailing!,
                style: const TextStyle(
                  color: AppColors.primaryTealDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ses dalgası biçiminde ilerleme çubuğu. [onSeek] verilirse dokunup sürükleyerek sarılabilir.
class Waveform extends StatelessWidget {
  final double progress; // 0-1
  final ValueChanged<double>? onSeek;
  final double height;
  static const int bars = 38;

  const Waveform({
    super.key,
    required this.progress,
    this.onSeek,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        void seek(double dx) => onSeek?.call((dx / c.maxWidth).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onSeek == null ? null : (d) => seek(d.localPosition.dx),
          onHorizontalDragUpdate: onSeek == null
              ? null
              : (d) => seek(d.localPosition.dx),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(painter: _WavePainter(progress)),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter(this.progress);

  /// Ses dalgasına benzeyen, her çizimde aynı çıkan sabit yükseklikler.
  static double _h(int i) {
    final v =
        0.55 +
        0.28 * math.sin(i * 0.9) +
        0.17 * math.sin(i * 2.3 + 1.1) +
        0.12 * math.sin(i * 5.1);
    return v.clamp(0.22, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const n = Waveform.bars;
    final slot = size.width / n;
    final w = slot * 0.56;
    final played = AppColors.primaryTeal;
    final rest = AppColors.primaryTeal.withValues(alpha: 0.28);
    for (var i = 0; i < n; i++) {
      final h = size.height * _h(i);
      final x = i * slot + (slot - w) / 2;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - h) / 2, w, h),
        Radius.circular(w / 2),
      );
      canvas.drawRRect(
        r,
        Paint()..color = (i + 0.5) / n <= progress ? played : rest,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}
