import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../common/app_network_image.dart';

/// Haritanın altında yüzen eser kartı. Eser balonunun tamamı dokunulabilir (sağdaki ok slider'ı açar).
/// Rota modunda üstte "Durak 2/4 · mesafe" ve önceki/sonraki okları görünür.
class RouteStopPreviewSheet extends StatelessWidget {
  final String? routeTitle;
  final String? routeStats; // örn: "Durak 2 / 6 · 3,8 km · 40 dk"
  final String placeName;
  final String placeDistanceTime;
  final String? placeImageUrl;
  final VoidCallback onDetailTap;
  final VoidCallback? onNextStopTap;
  final VoidCallback? onPrevStopTap;
  final VoidCallback? onCloseRoute;

  const RouteStopPreviewSheet({
    super.key,
    this.routeTitle,
    this.routeStats,
    required this.placeName,
    required this.placeDistanceTime,
    this.placeImageUrl,
    required this.onDetailTap,
    this.onNextStopTap,
    this.onPrevStopTap,
    this.onCloseRoute,
  });

  Widget _placeholder() => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: AppColors.borderSubtle,
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
  );

  Widget _stepButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: onTap == null
            ? AppColors.borderSubtle
            : AppColors.primaryTealLight,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              size: 22,
              color: onTap == null
                  ? AppColors.textMuted
                  : AppColors.primaryTealDark,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inRoute = routeTitle != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inRoute)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 2, 0, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (routeStats != null)
                          Text(
                            routeStats!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _stepButton(
                    context,
                    Icons.chevron_left_rounded,
                    context.t('prev_stop'),
                    onPrevStopTap,
                  ),
                  const SizedBox(width: 8),
                  _stepButton(
                    context,
                    Icons.chevron_right_rounded,
                    context.t('next_stop'),
                    onNextStopTap,
                  ),
                  if (onCloseRoute != null) ...[
                    const SizedBox(width: 4),
                    Semantics(
                      button: true,
                      label: context.t('route_close'),
                      excludeSemantics: true,
                      child: IconButton(
                        onPressed: onCloseRoute,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Semantics(
            button: true,
            label: placeName,
            hint: placeDistanceTime,
            excludeSemantics: true,
            onTap: onDetailTap,
            child: GestureDetector(
              onTap: onDetailTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgCanvas,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSubtle, width: 0.8),
                ),
                child: Row(
                  children: [
                    (placeImageUrl != null && placeImageUrl!.isNotEmpty)
                        ? AppNetworkImage(
                            imageUrl: placeImageUrl!,
                            width: 64,
                            height: 64,
                            borderRadius: BorderRadius.circular(14),
                          )
                        : _placeholder(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            placeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                          ),
                          if (placeDistanceTime.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              placeDistanceTime,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
