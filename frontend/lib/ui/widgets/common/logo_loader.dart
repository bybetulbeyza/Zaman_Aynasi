import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import 'app_logo.dart';

/// Yükleme göstergesi: Zaman Aynası logosu hafifçe nefes alır ve üzerinden bir ışık süzülür
/// (bir aynanın parıltısı gibi); dönen çark yok.
///
/// Kısa beklemeleri göstermez (0,25 sn altı), bekleme 2 sn'yi geçerse "Yükleniyor…" yazısı belirir,
/// 10 sn'yi geçerse "Bağlantı yavaş görünüyor" ve (verildiyse) "Tekrar dene" düğmesi çıkar.
class LogoLoader extends StatefulWidget {
  final double size;

  /// Yavaş bağlantı mesajında gösterilen "Tekrar dene" düğmesinin eylemi.
  final VoidCallback? onRetry;

  /// Koyu zeminlerde yazı rengini değiştirmek için.
  final Color? textColor;

  const LogoLoader({super.key, this.size = 56, this.onRetry, this.textColor});

  @override
  State<LogoLoader> createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat();

  bool _visible = false;
  bool _showText = false;
  bool _slow = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    void after(int ms, VoidCallback f) => _timers.add(
      Timer(Duration(milliseconds: ms), () {
        if (mounted) setState(f);
      }),
    );
    after(250, () => _visible = true);
    after(2000, () => _showText = true);
    after(10000, () => _slow = true);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final color = widget.textColor ?? AppColors.textMuted;
    return Semantics(
      label: context.t('loading_text'),
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (_, child) {
                final t = _c.value;
                // Nefes: 0.94 ↔ 1.0
                final breathe =
                    0.94 + 0.06 * (0.5 - 0.5 * math.cos(t * 2 * math.pi));
                return Transform.scale(
                  scale: breathe,
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (rect) => LinearGradient(
                      begin: const Alignment(-1, -0.6),
                      end: const Alignment(1, 0.6),
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: const [0.4, 0.5, 0.6],
                      transform: _Sweep(t * 2.4 - 1.2),
                    ).createShader(rect),
                    child: child,
                  ),
                );
              },
              child: ExcludeSemantics(child: AppLogo(size: widget.size)),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: _showText
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _slow
                                ? context.t('loading_slow')
                                : context.t('loading_text'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_slow && widget.onRetry != null)
                            TextButton(
                              onPressed: widget.onRetry,
                              child: Text(context.t('retry')),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sweep extends GradientTransform {
  final double percent;
  const _Sweep(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}
