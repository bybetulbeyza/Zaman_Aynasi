import 'package:flutter/material.dart';
import 'package:before_after/before_after.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/heritage_place.dart';

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
    this.beforeLabel = 'Dönem',
    this.afterLabel = 'Bugün',
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
  void disposedelegate() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 340.0;

        return Stack(
          children: [
            // 1. Before-After Karşılaştırma Katmanı
            SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: BeforeAfter(
                value: _sliderValue,
                before: Image.network(
                  widget.beforeImageUrl,
                  fit: BoxFit.cover,
                  width: totalWidth,
                  height: totalHeight,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.borderSubtle,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                    ),
                  ),
                ),
                after: Image.network(
                  widget.afterImageUrl,
                  fit: BoxFit.cover,
                  width: totalWidth,
                  height: totalHeight,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.borderSubtle,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                    ),
                  ),
                ),
                onValueChanged: (val) {
                  setState(() {
                    _sliderValue = val;
                  });
                },
              ),
            ),

            // 2. Sol Alt "Dönem" Etiketi
            Positioned(
              left: 16,
              bottom: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_sliderValue > 0.1) ? 1.0 : 0.0,
                child: _buildBadge(
                  widget.beforeLabel,
                  backgroundColor: AppColors.ciniCobalt.withOpacity(0.85),
                ),
              ),
            ),

            // 3. Sağ Alt "Bugün" Etiketi
            Positioned(
              right: 16,
              bottom: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_sliderValue < 0.9) ? 1.0 : 0.0,
                child: _buildBadge(
                  widget.afterLabel,
                  backgroundColor: AppColors.primaryTealDark.withOpacity(0.85),
                ),
              ),
            ),

            // 4. Dinamik Hotspot'lar (Oransal Çizim)
            if (_showHotspots)
              ...widget.hotspots.map((hotspot) {
                // Hotspot'un bulunduğu yatay konum (0.0 - 1.0)
                final isBeforeSide = hotspot.targetSide.toLowerCase() == 'before';
                final isVisible = isBeforeSide
                    ? (hotspot.xPercent < _sliderValue)
                    : (hotspot.xPercent > _sliderValue);

                if (!isVisible) return const SizedBox.shrink();

                // Gerçek piksel koordinatları
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}