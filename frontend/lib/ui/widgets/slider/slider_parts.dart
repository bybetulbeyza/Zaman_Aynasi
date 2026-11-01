import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Turu bilgi kartından başlatıp durdurmak için: slider (fotoğraf ya da 3B) kendini buraya bağlar.
class TourController extends ChangeNotifier {
  int stops = 0;
  bool touring = false;
  VoidCallback? _toggle;

  bool get available => stops >= 2 && _toggle != null;

  void toggle() => _toggle?.call();

  /// Slider'lar build sırasında çağırır; değişim yoksa bildirim göndermez.
  void sync(int stops, bool touring, VoidCallback? toggle) {
    if (this.stops == stops && this.touring == touring && _toggle == toggle) {
      return;
    }
    this.stops = stops;
    this.touring = touring;
    _toggle = toggle;
    notifyListeners();
  }
}

/// Fotoğraf slider'ındaki cam bölücü çizgi, tutamaç, rozet ve düğmelerin aynısı (3B görünümde de kullanılır).

class GlassDividerLine extends StatelessWidget {
  const GlassDividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 2.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.2, 0.8, 1.0],
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.45),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class GlassKnob extends StatefulWidget {
  final bool active;
  const GlassKnob({super.key, this.active = false});

  @override
  State<GlassKnob> createState() => _GlassKnobState();
}

class _GlassKnobState extends State<GlassKnob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    return super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.active ? 1.14 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Transform.scale(
                scale: 1.0 + _pulse.value * 0.28,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.42 - _pulse.value * 0.34,
                      ),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.46),
                        Colors.white.withValues(alpha: 0.14),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.75),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassBadge extends StatelessWidget {
  final String text;
  final Color tint;
  const GlassBadge(this.text, {super.key, required this.tint});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.38),
              width: 0.9,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tur / yakınlaştırma sıfırlama düğmeleri.
class GlassPill extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final String? text;
  final Color? tint;
  const GlassPill({
    super.key,
    required this.onTap,
    required this.label,
    required this.icon,
    this.text,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: text == null ? 10 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: tint != null
                    ? tint!.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.38),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  if (text != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      text!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
