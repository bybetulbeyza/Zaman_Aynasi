import 'package:flutter/material.dart';
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
    this.beforeLabel = 'Günümüz',
    this.afterLabel = 'Tarihi Dönem',
    this.hotspots = const [],
    this.onHotspotSelected,
  });

  @override
  State<SplitSliderWidget> createState() => _SplitSliderWidgetState();
}

class _SplitSliderWidgetState extends State<SplitSliderWidget>
    with SingleTickerProviderStateMixin {
  double _sliderValue = 0.5;
  bool _showHotspots = true;
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
                  setState(() {
                    _sliderValue = val;
                  });
                },
              ),
            ),

            // 2. Çift Oklu Tutamaç
            Positioned(
              left: dividerX - 1.0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 2.0,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            Positioned(
              left: dividerX - 18.0,
              top: (totalHeight / 2) - 18.0,
              child: IgnorePointer(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_left_rounded, size: 16, color: AppColors.textDark),
                      Icon(Icons.arrow_right_rounded, size: 16, color: AppColors.textDark),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Sol Üst: "Günümüz" Rozeti
            Positioned(
              left: 16,
              top: 68,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_sliderValue > 0.12) ? 1.0 : 0.0,
                child: _buildBadge(
                  widget.afterLabel,
                  backgroundColor: AppColors.primaryTealDark.withOpacity(0.85),
                ),
              ),
            ),

            // 4. Sağ Üst: "Tarihi Dönem" Rozeti
            Positioned(
              right: 16,
              top: 68,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_sliderValue < 0.88) ? 1.0 : 0.0,
                child: _buildBadge(
                  widget.beforeLabel,
                  backgroundColor: AppColors.ciniCobalt.withOpacity(0.85),
                ),
              ),
            ),

            // 5. Dinamik Hotspot'lar
            if (_showHotspots)
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

  Widget _buildBadge(String text, {required Color backgroundColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}