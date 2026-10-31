import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Uygulamanın tek bildirim stili: altta yüzen, koyu petrol, yuvarlak köşeli balon.
/// Alttan yukarı kayarak açılır, kapanırken de aşağı kayarak gider; aşağı çekilince de kapanır.
/// [actionLabel] verilirse sağda dokunulabilir bir düğme çıkar. Her zaman kendiliğinden kapanır.
class AppToast {
  static OverlayEntry? _entry;
  static _ToastController? _controller;

  /// [bottomMargin]: güvenli alt boşluğun üstünden uzaklık. Varsayılan, alt gezinme çubuğunun üstüdür.
  static void show(
    BuildContext context,
    String text, {
    IconData icon = Icons.check_rounded,
    String? actionLabel,
    VoidCallback? onAction,
    double bottomMargin = 78,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Öncekini beklemeden kaldır
    _entry?.remove();
    _entry = null;
    _controller = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final controller = _ToastController();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastView(
        controller: controller,
        text: text,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        bottom: MediaQuery.of(ctx).padding.bottom + bottomMargin,
        duration: duration,
        onGone: () {
          if (_entry == entry) {
            entry.remove();
            _entry = null;
            _controller = null;
          }
        },
      ),
    );
    _entry = entry;
    _controller = controller;
    overlay.insert(entry);
  }

  static void hide() => _controller?.dismiss();
}

class _ToastController {
  VoidCallback? _dismiss;
  void dismiss() => _dismiss?.call();
}

class _ToastView extends StatefulWidget {
  final _ToastController controller;
  final String text;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double bottom;
  final Duration duration;
  final VoidCallback onGone;

  const _ToastView({
    required this.controller,
    required this.text,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.bottom,
    required this.duration,
    required this.onGone,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    reverseDuration: const Duration(milliseconds: 280),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.controller._dismiss = _close;
    _anim.forward();
    _timer = Timer(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _anim.reverse();
    widget.onGone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(begin: const Offset(0, 1.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    return Positioned(
      left: 16,
      right: 16,
      bottom: widget.bottom,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _anim,
            curve: const Interval(0, 0.6),
            reverseCurve: const Interval(0.4, 1),
          ),
          child: GestureDetector(
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 150) _close();
            },
            child: Material(
              color: AppColors.heroPetrol,
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    8,
                    widget.actionLabel == null ? 14 : 8,
                    8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryTeal,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, size: 17, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null)
                        TextButton(
                          onPressed: () {
                            _close();
                            widget.onAction?.call();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.16,
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            textStyle: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text(widget.actionLabel!),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
