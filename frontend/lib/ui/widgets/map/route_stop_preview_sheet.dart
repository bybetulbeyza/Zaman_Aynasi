import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RouteStopPreviewSheet extends StatelessWidget {
  final String routeTitle;
  final String routeStats; // örn: "Durak 2 / 6 • 3,8 km • 2 sa 30 dk"
  final String placeName;
  final String placeDistanceTime; // örn: "240 m • 3 dk yürüyüş"
  final String? placeImageUrl;
  final VoidCallback onDetailTap;
  final VoidCallback onNextStopTap;

  const RouteStopPreviewSheet({
    super.key,
    required this.routeTitle,
    required this.routeStats,
    required this.placeName,
    required this.placeDistanceTime,
    this.placeImageUrl,
    required this.onDetailTap,
    required this.onNextStopTap,
  });

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: const Color(0xFFE2DED6),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textMuted,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Tutamaç (Handle)
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0DDD5),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Rota Başlığı
          Text(
            routeTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),

          // Rota Detay Metni
          Text(
            routeStats,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),

          // Seçili Durak Kartı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardSubBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Durak Görseli / İkonu (Boşsa veya hata verirse placeholder gösterir)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (placeImageUrl != null && placeImageUrl!.isNotEmpty)
                      ? Image.network(
                    placeImageUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  )
                      : _buildPlaceholder(),
                ),
                const SizedBox(width: 14),

                // İsim & Mesafe
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        placeDistanceTime,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Butonlar: Detay & Sonraki Durak
          Row(
            children: [
              // Detay Butonu (Outlined)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onDetailTap,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.leafGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Detay',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.leafGreen,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Sonraki Durak Butonu (Filled)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onNextStopTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.leafGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Sonraki durak',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}