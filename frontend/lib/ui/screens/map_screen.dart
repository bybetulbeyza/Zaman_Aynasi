import 'dart:async';

import '../widgets/common/app_icon.dart';
import '../widgets/common/logo_loader.dart';
import 'package:flutter/material.dart';
import '../widgets/common/app_toast.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/map_config.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/active_route.dart';
import '../../../core/utils/launcher_util.dart';
import '../../../core/utils/location_service.dart';
import '../../../data/models/heritage_place.dart';
import '../../../data/repositories/heritage_repository.dart';
import '../../core/utils/walking_route_service.dart';
import '../widgets/map/category_pin.dart';
import '../widgets/map/map_top_search_bar.dart';
import '../widgets/map/route_stop_preview_sheet.dart';
import 'slider_screen.dart';

class MapScreen extends StatefulWidget {
  final bool startWithNearby;

  const MapScreen({super.key, this.startWithNearby = false});

  @override
  State<MapScreen> createState() => MapScreenState();
}

/// Karoların yüklendiğini saymak için ağ karo sağlayıcısını sarar (ilk açılış yükleme ekranı için).
class _CountingTileProvider extends NetworkTileProvider {
  final VoidCallback onTile;
  _CountingTileProvider({required this.onTile});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final image = super.getImage(coordinates, options);
    image
        .resolve(ImageConfiguration.empty)
        .addListener(
          ImageStreamListener(
            (_, __) => onTile(),
            onError: (_, __) => onTile(),
          ),
        );
    return image;
  }
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final HeritageRepository _heritageRepository = HeritageRepository();

  final LatLng _bursaCenter = LocationService.defaultCenter;
  LatLng _userLocation = LocationService.defaultCenter;

  List<HeritagePlace> _allPlaces = [];
  List<HeritagePlace> _filteredPlaces = [];
  bool _isLoading = true;
  int _currentStopIndex = 0;
  bool _tilesReady =
      false; // ilk karolar gelene kadar logo yükleme ekranı gösterilir
  int _tilesLoaded = 0;
  Timer? _tilesTimeout;
  late final _CountingTileProvider _tileProvider = _CountingTileProvider(
    onTile: _onTileLoaded,
  );
  bool _cardOpen =
      false; // normal modda kart yalnızca bir pine dokunulunca açılır

  String _searchQuery = '';
  bool _hasRealLocation = false;
  String? _routeChip; // null | 'active' | 'nearby'
  WalkingRoute? _walk; // rota modunda sokakları izleyen hat
  PlaceCategory? _selectedCategory; // null = Tümü

  void _onTileLoaded() {
    if (_tilesReady || !mounted) return;
    if (++_tilesLoaded >= 4) setState(() => _tilesReady = true);
  }

  @override
  void dispose() {
    _tilesTimeout?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // İnternet yavaşsa bile yükleme ekranı sonsuza kadar kalmasın
    _tilesTimeout = Timer(const Duration(seconds: 7), () {
      if (mounted && !_tilesReady) setState(() => _tilesReady = true);
    });
    _initDataAndLocation();
  }

  Future<void> _initDataAndLocation() async {
    final places = await _heritageRepository.getPlaces();
    if (!mounted) return;

    // "Yakın rota" konuma ihtiyaç duyar; diğer durumda harita konumu beklemeden açılır.
    if (widget.startWithNearby) {
      _userLocation = await LocationService.getCurrentLocation();
      _hasRealLocation = !LocationService.lastWasFallback;
      if (!mounted) return;
    }

    setState(() {
      _allPlaces = places;
      _isLoading = false;
    });

    if (widget.startWithNearby) {
      applyNearbyRoute();
    } else {
      _applyFilters();
      _resolveUserLocation();
    }
  }

  /// Konum ve izin penceresi haritayı geciktirmesin diye arka planda çözülür.
  Future<void> _resolveUserLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _userLocation = loc;
      _hasRealLocation = !LocationService.lastWasFallback;
    });
  }

  /// Dışarıdan veya butondan tetiklenebilen "Yakın Rota" Mantığı
  void applyNearbyRoute() {
    if (_allPlaces.isEmpty) return;

    // Nearest Neighbor ile sıralanmış liste
    final sorted = LocationService.optimizeRouteOrder(
      places: _allPlaces,
      startLocation: _userLocation,
    );

    setState(() {
      _routeChip = 'nearby';
      _walk = null;
      // En yakından başlayarak ilk 4 durağı rotaya bağla
      _filteredPlaces = sorted.take(4).toList();
      _currentStopIndex = 0;
    });

    if (_filteredPlaces.isNotEmpty) {
      _moveMap(_filteredPlaces.first.location, 16.5);
    }
    _loadWalkingRoute();

    AppToast.show(
      context,
      context.t('nearby_route_ready'),
      icon: Icons.near_me_rounded,
      duration: const Duration(seconds: 3),
    );
  }

  /// RoutesScreen üzerinden gelen özel rotayı haritaya yükleme
  void loadCustomRoute(List<HeritagePlace> places, {int focusIndex = 0}) {
    if (places.isEmpty) return;
    final focus = focusIndex.clamp(0, places.length - 1);
    setState(() {
      _routeChip = 'active';
      _walk = null;
      _filteredPlaces = places;
      _currentStopIndex = focus;
    });
    _moveMap(places[focus].location, 16.5);
    _loadWalkingRoute();
  }

  /// Harita henüz çizilmediyse (ilk açılış) hareketi ilk çerçeveden sonraya bırakır.
  void _moveMap(LatLng target, double zoom) {
    try {
      _mapController.move(target, zoom);
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(target, zoom);
        } catch (_) {}
      });
    }
  }

  List<Marker> _buildPinMarkers() {
    final markers = List.generate(_filteredPlaces.length, (index) {
      final place = _filteredPlaces[index];
      final isSelected =
          (_routeChip != null || _cardOpen) && index == _currentStopIndex;
      return Marker(
        point: place.location,
        width: CategoryPin.width * 1.2,
        height: CategoryPin.height * 1.2,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _currentStopIndex = index;
              _cardOpen = true;
            });
            _moveMap(place.location, 16.8);
          },
          child: Semantics(
            button: true,
            label: context
                .t('a11y_pin')
                .replaceAll('{name}', place.nameFor(context.isEn)),
            excludeSemantics: true,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CategoryPin(
                category: place.category,
                selected: isSelected,
                order: _routeChip != null ? index + 1 : null,
              ),
            ),
          ),
        ),
      );
    });
    // Seçili pin üst üste binen pinlerin önünde görünsün
    if (_currentStopIndex < markers.length) {
      markers.add(markers.removeAt(_currentStopIndex));
    }
    return markers;
  }

  /// Rota modunda duraklar arası gerçek yürüyüş hattını çeker; olmazsa düz çizgi kullanılır.
  Future<void> _loadWalkingRoute() async {
    final stops = _filteredPlaces.map((p) => p.location).toList();
    final key = _routeChip;
    final route = await WalkingRouteService.fetch(stops);
    if (!mounted || _routeChip != key) return;
    setState(() => _walk = route);
  }

  void _recenter() {
    if (!_hasRealLocation) {
      AppToast.show(
        context,
        context.t('location_off_note'),
        icon: Icons.location_off_rounded,
      );
      return;
    }
    _moveMap(_userLocation, 16.5);
  }

  /// Rotayı haritadan kapatır. Hazırladığı rotaysa (aktif rota) silinir; "Geri al" ile geri gelir.
  void _closeRoute() {
    final wasActive = _routeChip == 'active';
    final stops = ActiveRoute.instance.stops;
    final titleTr = ActiveRoute.instance.titleFor(false);
    final titleEn = ActiveRoute.instance.titleFor(true);
    setState(() {
      _routeChip = null;
      _walk = null;
      _cardOpen = false;
    });
    _applyFilters();
    if (!wasActive) return;
    ActiveRoute.instance.clear();
    AppToast.show(
      context,
      context.t('route_closed'),
      icon: Icons.remove_circle_outline_rounded,
      actionLabel: context.t('undo'),
      onAction: () {
        ActiveRoute.instance.setRoute(
          stops,
          titleTr: titleTr,
          titleEn: titleEn,
        );
        loadCustomRoute(stops);
      },
    );
  }

  void _stepStop(int delta) {
    final n = _filteredPlaces.length;
    if (n == 0) return;
    setState(() => _currentStopIndex = (_currentStopIndex + delta + n) % n);
    _moveMap(_filteredPlaces[_currentStopIndex].location, 16.8);
  }

  /// Kartta eserin altındaki satır: gerçek konum yakınsa mesafe, değilse kategori.
  String _subtitleFor(HeritagePlace place) {
    final category = place.category.labelFor(context.isEn);
    if (!_hasRealLocation) return category;
    final meters = const Distance().as(
      LengthUnit.Meter,
      _userLocation,
      place.location,
    );
    if (meters > 150000) return category;
    return '$category · ${LocationService.formatDistance(meters)}';
  }

  void _applyFilters() {
    setState(() {
      final filtered = _allPlaces.where((place) {
        final q = _searchQuery.toLowerCase();
        final matchesSearch =
            place.name.toLowerCase().contains(q) ||
            place.city.toLowerCase().contains(q) ||
            place.nameEn.toLowerCase().contains(q) ||
            place.shortDescription.toLowerCase().contains(q) ||
            place.shortDescriptionEn.toLowerCase().contains(q);

        final matchesCategory =
            _selectedCategory == null || place.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();

      // Normal filtrede de zikzak olmaması için durakları optimize et
      _filteredPlaces = LocationService.optimizeRouteOrder(
        places: filtered,
        startLocation: _userLocation,
      );

      if (_currentStopIndex >= _filteredPlaces.length) {
        _currentStopIndex = 0;
      }
      _cardOpen = false;
    });

    if (!_isLoading && _filteredPlaces.isNotEmpty) {
      _moveMap(_filteredPlaces[_currentStopIndex].location, 16.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: LogoLoader(size: 64),
      );
    }

    if (_allPlaces.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t('map_load_error'),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _initDataAndLocation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                ),
                child: Text(
                  context.t('retry'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasPlaces = _filteredPlaces.isNotEmpty;
    final currentPlace = hasPlaces ? _filteredPlaces[_currentStopIndex] : null;
    final showCard = currentPlace != null && (_routeChip != null || _cardOpen);
    final List<LatLng> routePoints = _filteredPlaces
        .map((p) => p.location)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          // 1. Harita Katmanı
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _allPlaces.isNotEmpty
                  ? _allPlaces.first.location
                  : _bursaCenter,
              initialZoom: 16.5,
              backgroundColor: AppColors.bgCanvas,
              onTap: (_, __) {
                if (_routeChip == null && _cardOpen) {
                  setState(() => _cardOpen = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                tileProvider: _tileProvider,
                tileSize: MapConfig.tileSize,
                zoomOffset: MapConfig.zoomOffset,
                userAgentPackageName: 'com.zamanaynasi.app',
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution(
                    MapConfig.useMapbox
                        ? '© Mapbox © OpenStreetMap'
                        : '© OpenStreetMap contributors',
                  ),
                ],
              ),

              // Rota hattı yalnızca bir rota seçiliyken çizilir (cam hissi: açık halka + canlı çekirdek)
              if (_routeChip != null && routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _walk?.points ?? routePoints,
                      strokeWidth: 5.0,
                      color: AppColors.primaryTeal,
                      borderStrokeWidth: 4.0,
                      borderColor: Colors.white.withValues(alpha: 0.75),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),

              // Kullanıcının konumu (gerçek konum varsa)
              if (_hasRealLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation,
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryTeal.withValues(alpha: 0.22),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              // Kategori pinleri (rota modunda sıra rozetli)
              MarkerLayer(markers: _buildPinMarkers()),
            ],
          ),

          // İlk harita karoları gelene kadar logo yükleme ekranı
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _tilesReady,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 350),
                opacity: _tilesReady ? 0 : 1,
                child: const ColoredBox(
                  color: AppColors.bgCanvas,
                  child: LogoLoader(size: 64),
                ),
              ),
            ),
          ),

          // 2. Üst Arama ve Filtre Çubuğu
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: MapTopSearchBar(
              routeLabel: _routeChip == null
                  ? null
                  : context
                        .t('route_chip')
                        .replaceAll(
                          '{name}',
                          _routeChip == 'active'
                              ? (ActiveRoute.instance.titleFor(context.isEn) ??
                                    context.t('ar_title'))
                              : context.t('nearby_route_title'),
                        ),
              onSearchChanged: (query) {
                _routeChip = null;
                _walk = null;
                _searchQuery = query;
                _applyFilters();
              },
              onFilterSelected: (category) {
                _routeChip = null;
                _walk = null;
                _selectedCategory = category;
                _applyFilters();
              },
            ),
          ),

          // 3. Alt alan: konum düğmesi, yol tarifi ve (gerektiğinde) eser kartı
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Sağda dikey yuvarlak ikili: yol tarifi (eser seçiliyse) ve konumum
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, showCard ? 10 : 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showCard) ...[
                        Semantics(
                          button: true,
                          label: context.t('directions'),
                          excludeSemantics: true,
                          child: Material(
                            color: AppColors.primaryTeal,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => LauncherUtil.openDirections(
                                currentPlace.location,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(15),
                                child: AppIcon(
                                  'directions',
                                  size: 26,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Semantics(
                        button: true,
                        label: context.t('locate_me'),
                        excludeSemantics: true,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _recenter,
                            child: const Padding(
                              padding: EdgeInsets.all(15),
                              child: AppIcon(
                                'locate',
                                color: AppColors.primaryTeal,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  child: showCard
                      ? RouteStopPreviewSheet(
                          routeTitle: _routeChip == null
                              ? null
                              : (currentPlace.routeName.isNotEmpty
                                    ? currentPlace.routeNameFor(context.isEn)
                                    : context.t('nearby_route_title')),
                          routeStats: _routeChip == null
                              ? null
                              : context
                                        .t('stop_of')
                                        .replaceAll(
                                          '{i}',
                                          '${_currentStopIndex + 1}',
                                        )
                                        .replaceAll(
                                          '{n}',
                                          '${_filteredPlaces.length}',
                                        ) +
                                    (_walk == null
                                        ? ''
                                        : ' · ${_walk!.distanceLabel} · ${_walk!.minutes} ${context.t('min_walk')}'),
                          placeName: currentPlace.nameFor(context.isEn),
                          placeDistanceTime: _subtitleFor(currentPlace),
                          placeImageUrl: currentPlace.imageAfterUrl,
                          onDetailTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SliderScreen(place: currentPlace),
                            ),
                          ),
                          onCloseRoute: _routeChip != null ? _closeRoute : null,
                          stopCount: _routeChip != null
                              ? _filteredPlaces.length
                              : 0,
                          stopIndex: _currentStopIndex,
                          onPrevStopTap:
                              (_routeChip != null && _filteredPlaces.length > 1)
                              ? () => _stepStop(-1)
                              : null,
                          onNextStopTap:
                              (_routeChip != null && _filteredPlaces.length > 1)
                              ? () => _stepStop(1)
                              : null,
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
