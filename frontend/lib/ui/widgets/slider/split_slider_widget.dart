import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:before_after/before_after.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_network_image.dart';

class SplitSliderWidget extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final String beforeLabel;
  final String afterLabel;
  final List<Hotspot> hotspots;
  final ValueChanged<Hotspot>? onHotspotSelected;

  const SplitSliderWidget({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.beforeLabel = 'Bugün',
    this.afterLabel = 'Dönem',
    this.hotspots = const [],
    this.onHotspotSelected,
  });

  @override
  State<SplitSliderWidget> createState() => _SplitSliderWidgetState();
}

class _SplitSliderWidgetState extends State<SplitSliderWidget>
    with SingleTickerProviderStateMixin {
  double _sliderValue = 0.5;
  bool _active = false; // kullanıcı slider'ı sürüklerken tutamaç büyür
  Timer? _activeTimer;
  bool _showHotspots = true;
  bool _coordinatePickerMode = false; // Koordinat yakalama anahtarı
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 340.0;
        final dividerX = _sliderValue * totalWidth;

        return Stack(
          children: [
            // 1. Before-After Karşılaştırma Katmanı
            SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: BeforeAfter(
                value: _sliderValue,
                before: AppNetworkImage(
                  imageUrl: widget.afterImageUrl,
                  width: totalWidth,
                  height: totalHeight,
                ),
                after: AppNetworkImage(
                  imageUrl: widget.beforeImageUrl,
                  width: totalWidth,
                  height: totalHeight,
                ),
                onValueChanged: (val) {
                  if (!_coordinatePickerMode) {
                    // Dörtte bir çizgilerini geçerken hafif titreşim
                    if ((val * 4).floor() != (_sliderValue * 4).floor()) {
                      HapticFeedback.selectionClick();
                    }
                    _activeTimer?.cancel();
                    _activeTimer = Timer(const Duration(milliseconds: 260), () {
                      if (mounted) setState(() => _active = false);
                    });
                    setState(() {
                      _sliderValue = val;
                      _active = true;
                    });
                  }
                },
              ),
            ),

            // 2. Cam efektli bölücü çizgi ve tutamaç
            Positioned(
              left: dividerX - 1.25,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
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
              ),
            ),
            Positioned(
              left: dividerX - 28.0,
              top: (totalHeight * 0.5) - 28.0,
              child: IgnorePointer(
                child: AnimatedScale(
                  scale: _active ? 1.14 : 1.0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  child: _buildGlassKnob(),
                ),
              ),
            ),

            // 3. Sol üst: Dönem rozeti (cam)
            Positioned(
              left: 16,
              top: 68,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_sliderValue > 0.12) ? 1.0 : 0.0,
                child: _buildBadge(
                  widget.afterLabel,
                  tint: AppColors.primaryTealDark,
                ),
              ),
            ),

            // 4. Sağ üst: Bugün rozeti (cam)
            Positioned(
              right: 16,
              top: 68,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_sliderValue < 0.88) ? 1.0 : 0.0,
                child: _buildBadge(
                  widget.beforeLabel,
                  tint: AppColors.ciniCobalt,
                ),
              ),
            ),

            // 5. Dinamik Hotspot'lar
            if (_showHotspots && !_coordinatePickerMode)
              ...widget.hotspots.map((hotspot) {
                final isBeforeSide = hotspot.targetSide.toLowerCase() == 'before';
                final isVisible = isBeforeSide
                    ? (hotspot.xPercent > _sliderValue)
                    : (hotspot.xPercent < _sliderValue);

                if (!isVisible) return const SizedBox.shrink();

                final leftPos = (hotspot.xPercent * totalWidth).clamp(20.0, totalWidth - 40.0);
                final topPos = (hotspot.yPercent * totalHeight).clamp(20.0, totalHeight - 40.0);

                return Positioned(
                  left: leftPos - 16,
                  top: topPos - 16,
                  child: _buildAnimatedHotspot(
                    onTap: () {
                      if (widget.onHotspotSelected != null) {
                        widget.onHotspotSelected!(hotspot);
                      }
                    },
                  ),
                );
              }),

            // 6. En Üst Katman: KOORDİNAT YAKALAYICI PERDE (Aktifken dokunmaları doğrudan kapar)
            if (_coordinatePickerMode)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final x = (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
                    final y = (details.localPosition.dy / totalHeight).clamp(0.0, 1.0);
                    final side = (details.localPosition.dx < dividerX) ? 'after' : 'before';

                    final xStr = x.toStringAsFixed(2);
                    final yStr = y.toStringAsFixed(2);

                    // 1. Terminale / Konsola yazdırır
                    debugPrint('📍 YENİ HOTSPOT -> x_percent: $xStr | y_percent: $yStr | target_side: $side');

                    // 2. Ekranda direkt bildirim olarak gösterir
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('x_percent: $xStr, y_percent: $yStr, side: $side'),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.ciniBordeaux,
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.15),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Nokta koymak istediğin yere tıkla',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),

            // 7. Modu Açıp Kapatma Butonu (Sol Alt Köşe)
            if (kDebugMode)
            Positioned(
              left: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: 'coordPickerBtn',
                backgroundColor: _coordinatePickerMode ? AppColors.ciniBordeaux : Colors.white,
                onPressed: () {
                  setState(() {
                    _coordinatePickerMode = !_coordinatePickerMode;
                  });
                },
                child: Icon(
                  _coordinatePickerMode ? Icons.check_rounded : Icons.add_location_alt_outlined,
                  color: _coordinatePickerMode ? Colors.white : AppColors.textDark,
                  size: 20,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedHotspot({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.25);
          final opacity = 0.35 - (_pulseController.value * 0.20);

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(opacity.clamp(0.08, 0.4)),
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Buzlu cam görünümlü tutamaç: dıştaki halka nabız gibi atar, ortada iki ok vardır.
  Widget _buildGlassKnob() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + _pulseController.value * 0.28,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.42 - _pulseController.value * 0.34),
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.3),
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
                    Icon(Icons.chevron_left_rounded, size: 20, color: Colors.white),
                    Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, {required Color tint}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.38), width: 0.9),
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
