import '../common/dark_cancel.dart';
import '../common/app_card.dart';
import '../common/pattern_background.dart';
import '../common/sheet_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/category_style.dart';
import '../../../core/constants/map_config.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';
import '../../../data/models/heritage_route.dart';
import '../common/app_icon.dart';
import '../common/app_network_image.dart';
import '../common/pill_button.dart';

/// Hazır rotanın duraklarını gösteren etkileşimli sayfa: mini harita önizlemesi,
/// fotoğraflı duraklar, duraklar arası yürüme süresi. Bir durağa dokununca haritada o durak açılır.
Future<void> showRouteStopsSheet(
  BuildContext context, {
  required HeritageRoute route,
  required void Function(int stopIndex) onStopTap,
  required VoidCallback onStart,
}) {
  return showModalBottomSheet<void>(
    context: context,
    constraints: kSheetConstraints,
    clipBehavior: Clip.antiAlias,
    isScrollControlled: true,
    backgroundColor: canvasOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => PatternBackground(
        lineOpacity: 0.07,
        child: _RouteStopsContent(
          route: route,
          controller: controller,
          onStopTap: (i) {
            Navigator.pop(sheetContext);
            onStopTap(i);
          },
          onStart: () {
            Navigator.pop(sheetContext);
            onStart();
          },
        ),
      ),
    ),
  );
}

class _RouteStopsContent extends StatelessWidget {
  final HeritageRoute route;
  final ScrollController controller;
  final void Function(int) onStopTap;
  final VoidCallback onStart;

  const _RouteStopsContent({
    required this.route,
    required this.controller,
    required this.onStopTap,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final en = context.isEn;
    final stats =
        '${route.stops.length} ${context.t('stops_word')} · ${route.durationLabelFor(en)}'
        '${route.isWalkingExact ? ' ${context.t('walk_word')}' : ''} · ${route.distanceLabelFor(en)}';

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            children: [
              const SheetHandle(),
              Text(route.nameFor(en), style: AppTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                stats,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              _MapPreview(route: route, onTap: () => onStopTap(0)),
              const SizedBox(height: 18),
              Text(
                context.t('stops_hint'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < route.stops.length; i++) ...[
                _StopTile(
                  index: i,
                  place: route.stops[i],
                  onTap: () => onStopTap(i),
                ),
                if (i < route.stops.length - 1) _legConnector(context, i),
              ],
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            14 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: canvasOf(context),
            border: Border(
              top: BorderSide(
                color: AppColors.chipBorder.withValues(alpha: 0.9),
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: PillButton(context.t('hr_start'), onPressed: onStart),
          ),
        ),
      ],
    );
  }

  /// İki durak arasındaki yürüme süresi ve mesafesi (servisten geldiyse).
  Widget _legConnector(BuildContext context, int i) {
    final hasLeg = i < route.legs.length;
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
      child: Row(
        children: [
          Container(width: 2, height: 26, color: AppColors.chipBorder),
          const SizedBox(width: 14),
          if (hasLeg)
            Text(
              context
                  .t('walk_between')
                  .replaceAll('{m}', '${route.legs[i].minutes}')
                  .replaceAll('{d}', route.legs[i].distanceLabel),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  final int index;
  final HeritagePlace place;
  final VoidCallback onTap;

  const _StopTile({
    required this.index,
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final en = context.isEn;
    final style = CategoryStyle.of(place.category);
    return Material(
      color: Colors.white,
      shape: appCardBorder(round: 22),
      child: InkWell(
        customBorder: appCardBorder(round: 22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: ShapeDecoration(shape: appCardBorder(round: 22)),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AppNetworkImage(
                imageUrl: place.imageAfterUrl,
                width: 58,
                height: 58,
                borderRadius: BorderRadius.circular(12),
                semanticLabel: place.nameFor(en),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.nameFor(en),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppIcon(style.icon, size: 16, color: style.color),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            place.category.labelFor(en),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: style.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rotanın dokunulamaz mini harita önizlemesi; dokununca tam haritada açılır.
class _MapPreview extends StatelessWidget {
  final HeritageRoute route;
  final VoidCallback onTap;

  const _MapPreview({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final line = route.path.isNotEmpty
        ? route.path
        : route.stops.map((s) => s.location).toList();
    final bounds = LatLngBounds.fromPoints(line);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 170,
          child: Stack(
            children: [
              IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(34),
                      maxZoom: 17,
                    ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapConfig.tileUrl,
                      tileSize: MapConfig.tileSize,
                      zoomOffset: MapConfig.zoomOffset,
                      userAgentPackageName: 'com.zamanaynasi.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: line,
                          strokeWidth: 4.5,
                          color: AppColors.primaryTeal,
                          borderStrokeWidth: 3,
                          borderColor: Colors.white.withValues(alpha: 0.75),
                          strokeCap: StrokeCap.round,
                          strokeJoin: StrokeJoin.round,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        for (var i = 0; i < route.stops.length; i++)
                          Marker(
                            point: route.stops[i].location,
                            width: 26,
                            height: 26,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: CategoryStyle.of(
                                  route.stops[i].category,
                                ).color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    context.t('open_in_map'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
