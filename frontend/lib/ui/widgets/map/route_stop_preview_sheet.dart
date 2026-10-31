import 'package:flutter/semantics.dart';
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

  /// Rota modunda durak sayısı ve sıradaki durak (nokta göstergesi için).
  final int stopCount;
  final int stopIndex;

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
    this.stopCount = 0,
    this.stopIndex = 0,
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
            customSemanticsActions: {
              if (onNextStopTap != null)
                CustomSemanticsAction(label: context.t('next_stop')):
                    onNextStopTap!,
              if (onPrevStopTap != null)
                CustomSemanticsAction(label: context.t('prev_stop')):
                    onPrevStopTap!,
            },
            child: GestureDetector(
              onTap: onDetailTap,
              // Rota modunda kartı sağa/sola kaydırarak durak değiştirilir
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -250) onNextStopTap?.call();
                if (v > 250) onPrevStopTap?.call();
              },
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
          if (stopCount > 1 && stopCount <= 12)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < stopCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == stopIndex ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == stopIndex
                            ? AppColors.primaryTeal
                            : AppColors.chipBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
