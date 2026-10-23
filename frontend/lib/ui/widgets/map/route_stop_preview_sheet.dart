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
      width: 72,
      height: 72,
      color: AppColors.borderSubtle,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textMuted,
        size: 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Tutamaç (Handle)
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Rota Başlığı
          Text(
            routeTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),

          // Rota Detay Metni (Durak sayısı, toplam km, süre)
          Text(
            routeStats,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),

          // Seçili Durak Kartı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCanvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                // Durak Görseli
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (placeImageUrl != null && placeImageUrl!.isNotEmpty)
                      ? Image.network(
                    placeImageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  )
                      : _buildPlaceholder(),
                ),
                const SizedBox(width: 14),

                // İsim & Yürüme Mesafesi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        placeDistanceTime,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: onDetailTap,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.chipInactiveBg,
                      side: const BorderSide(
                        color: AppColors.chipBorder,
                        width: 1.0,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    child: const Text(
                      'Detay',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: onNextStopTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    child: const Text(
                      'Sonraki durak',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
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