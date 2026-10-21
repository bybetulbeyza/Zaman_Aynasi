import 'package:flutter/material.dart';
import 'package:before_after/before_after.dart';

class SplitSliderWidget extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final String beforeLabel;
  final String afterLabel;

  const SplitSliderWidget({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.beforeLabel = '1890 (Temsili Canlandırma)',
    this.afterLabel = '2026 Günümüz',
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

  void _showHotspotSheet(String title, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 1. Slider (Solda Eski 1890, Sağda Yeni 2026)
              BeforeAfter(
                value: _sliderValue,
                before: Image.network(
                  widget.beforeImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                after: Image.network(
                  widget.afterImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                onValueChanged: (val) {
                  setState(() {
                    _sliderValue = val;
                  });
                },
              ), // <-- Virgül eklendi

              // 2. Sol Üst: Eski Etiketi
              Positioned(
                top: 14,
                left: 14,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: (_sliderValue > 0.15)
                      ? ((_sliderValue - 0.15) / 0.5).clamp(0.0, 1.0)
                      : 0.0,
                  child: _buildBadge(widget.beforeLabel),
                ),
              ),

              // 3. Sağ Üst: Günümüz Etiketi
              Positioned(
                top: 14,
                right: 14,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: (_sliderValue < 0.85)
                      ? ((0.85 - _sliderValue) / 0.5).clamp(0.0, 1.0) // Eksi düzeltildi
                      : 0.0,
                  child: _buildBadge(widget.afterLabel),
                ),
              ),

              // 4. Minimal Hotspotlar
              if (_showHotspots) ...[
                if (_sliderValue > 0.40)
                  Positioned(
                    top: 80,
                    left: 130,
                    child: _buildMinimalHotspot(
                      onTap: () => _showHotspotSheet(
                        'Almaşık Alınlık ve Tepe Penceresi',
                        'Erken Osmanlı dönemine özgü sıralı taş-tuğla örgü ve havalandırma filgözü açıklığı.',
                      ),
                    ),
                  ),
                if (_sliderValue < 0.60)
                  Positioned(
                    bottom: 130,
                    right: 120,
                    child: _buildMinimalHotspot(
                      onTap: () => _showHotspotSheet(
                        'Hamamdan Çarşıya Dönüşüm',
                        '1958 yangını sonrası hamam camekânı ve soğukluğu dükkânlara dönüştürülerek Aynalı Çarşı işlevini kazanmıştır.',
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showHotspots = !_showHotspots;
                });
              },
              icon: Icon(
                _showHotspots ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 15,
                color: Colors.grey.shade400,
              ),
              label: Text(
                _showHotspots ? 'Detay Noktalarını Gizle' : 'Detay Noktalarını Göster',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalHotspot({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.35);
          final opacity = 0.35 - (_pulseController.value * 0.25); // Eksi düzeltildi

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(opacity.clamp(0.05, 0.4)),
                  ),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2C2C2E).withOpacity(0.70),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.60),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}