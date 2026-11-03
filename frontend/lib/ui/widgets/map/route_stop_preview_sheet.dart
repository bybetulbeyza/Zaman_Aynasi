import '../common/app_card.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../common/app_network_image.dart';
import '../common/dark_cancel.dart';

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
    width: 116,
    height: 116,
    decoration: BoxDecoration(
      color: AppColors.borderSubtle,
      borderRadius: BorderRadius.circular(22),
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
  );

  @override
  Widget build(BuildContext context) {
    final inRoute = routeTitle != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: AppColors.cardBg,
        shape: appCardBorder(
          round: 36,
          side: bordeauxOf(context).withValues(alpha: 0.4),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
              child: SizedBox(
                height: 116,
                child: Row(
                  children: [
                    (placeImageUrl != null && placeImageUrl!.isNotEmpty)
                        ? AppNetworkImage(
                            imageUrl: placeImageUrl!,
                            width: 116,
                            height: 116,
                            borderRadius: BorderRadius.circular(22),
                          )
                        : _placeholder(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (placeDistanceTime.isNotEmpty)
                                Text(
                                  placeDistanceTime,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                    color: bordeauxOf(context),
                                  ),
                                ),
                              const SizedBox(height: 3),
                              Text(
                                placeName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.titleMedium.copyWith(
                                  fontSize: 22,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                          // "Eseri keşfet" rozeti: sıradaki mühür kartındaki rozetle aynı
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                              decoration: BoxDecoration(
                                color: AppColors.ciniBordeauxLight,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: bordeauxOf(
                                    context,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.t('explore_place'),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: bordeauxOf(context),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: bordeauxOf(context),
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
