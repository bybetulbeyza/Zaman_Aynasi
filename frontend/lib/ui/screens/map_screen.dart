import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/active_route.dart';
import '../../../core/utils/launcher_util.dart';
import '../../../core/utils/location_service.dart';
import '../../../data/models/heritage_place.dart';
import '../../../data/repositories/heritage_repository.dart';
import '../widgets/map/map_top_search_bar.dart';
import '../widgets/map/route_stop_preview_sheet.dart';
import 'slider_screen.dart';

class MapScreen extends StatefulWidget {
  final bool startWithNearby;

  const MapScreen({super.key, this.startWithNearby = false});

  @override
  State<MapScreen> createState() => MapScreenState();
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

  String _searchQuery = '';
  bool _hasRealLocation = false;
  String? _routeChip; // null | 'active' | 'nearby'
  PlaceCategory? _selectedCategory; // null = Tümü

  @override
  void initState() {
    super.initState();
    _initDataAndLocation();
  }

  Future<void> _initDataAndLocation() async {
    final places = await _heritageRepository.getPlaces();
    _userLocation = await LocationService.getCurrentLocation();
    _hasRealLocation = !LocationService.lastWasFallback;

    if (mounted) {
      setState(() {
        _allPlaces = places;
        _isLoading = false;
      });

      if (widget.startWithNearby) {
        applyNearbyRoute();
      } else {
        _applyFilters();
      }

      // Önceden görsel önbellekleme
      for (final place in places) {
        if (place.imageAfterUrl.isNotEmpty) {
          precacheImage(NetworkImage(place.imageAfterUrl), context);
        }
        if (place.imageBeforeUrl.isNotEmpty) {
          precacheImage(NetworkImage(place.imageBeforeUrl), context);
        }
      }
    }
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
      // En yakından başlayarak ilk 4 durağı rotaya bağla
      _filteredPlaces = sorted.take(4).toList();
      _currentStopIndex = 0;
    });

    if (_filteredPlaces.isNotEmpty) {
      _mapController.move(_filteredPlaces.first.location, 16.5);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(context.t('nearby_route_ready'))),
          ],
        ),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// RoutesScreen üzerinden gelen özel rotayı haritaya yükleme
  void loadCustomRoute(List<HeritagePlace> places) {
    if (places.isEmpty) return;
    setState(() {
      _routeChip = 'active';
      _filteredPlaces = places;
      _currentStopIndex = 0;
    });
    _mapController.move(places.first.location, 16.5);
  }

  void _recenter() {
    if (!_hasRealLocation) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.t('location_off_note'))));
      return;
    }
    _mapController.move(_userLocation, 16.5);
  }

  void _applyFilters() {
    setState(() {
      final filtered = _allPlaces.where((place) {
        final q = _searchQuery.toLowerCase();
        final matchesSearch = place.name.toLowerCase().contains(q) ||
            place.nameEn.toLowerCase().contains(q) ||
            place.shortDescription.toLowerCase().contains(q) ||
            place.shortDescriptionEn.toLowerCase().contains(q);

        final matchesCategory = _selectedCategory == null || place.category == _selectedCategory;

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
    });

    if (!_isLoading && _filteredPlaces.isNotEmpty) {
      _mapController.move(_filteredPlaces[_currentStopIndex].location, 16.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
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
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _initDataAndLocation();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                child: Text(context.t('retry'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final hasPlaces = _filteredPlaces.isNotEmpty;
    final currentPlace = hasPlaces ? _filteredPlaces[_currentStopIndex] : null;
    final List<LatLng> routePoints = _filteredPlaces.map((p) => p.location).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          // 1. Harita Katmanı
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _allPlaces.isNotEmpty ? _allPlaces.first.location : _bursaCenter,
              initialZoom: 16.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zamanaynasi.app',
              ),

              // Mantıksal Sıralı Rota Çizgisi
              if (routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: AppColors.primaryTeal,
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

              // Numaralı Durak Pinleri (1, 2, 3...)
              MarkerLayer(
                markers: List.generate(_filteredPlaces.length, (index) {
                  final place = _filteredPlaces[index];
                  final isSelected = index == _currentStopIndex;

                  return Marker(
                    point: place.location,
                    width: isSelected ? 44 : 36,
                    height: isSelected ? 44 : 36,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentStopIndex = index;
                        });
                        _mapController.move(place.location, 16.8);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.ciniBordeaux
                              : AppColors.primaryTeal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          // 2. Üst Arama ve Filtre Çubuğu
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: MapTopSearchBar(
              routeLabel: _routeChip == null
                  ? null
                  : context.t('route_chip').replaceAll(
                      '{name}',
                      _routeChip == 'active'
                          ? (ActiveRoute.instance.titleFor(context.isEn) ??
                              context.t('ar_title'))
                          : context.t('nearby_route_title')),
              onSearchChanged: (query) {
                _routeChip = null;
                _searchQuery = query;
                _applyFilters();
              },
              onFilterSelected: (category) {
                _routeChip = null;
                _selectedCategory = category;
                _applyFilters();
              },
            ),
          ),

          // 3. Alt Durak Kartı
          if (currentPlace != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Konumuma dön
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 3,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _recenter,
                            child: const Padding(
                              padding: EdgeInsets.all(15),
                              child: Icon(Icons.my_location_rounded,
                                  color: AppColors.primaryTeal),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => LauncherUtil.openDirections(currentPlace.location),
                          icon: const Icon(Icons.north_east_rounded, size: 18),
                          label: Text(context.t('directions')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: const StadiumBorder(),
                            textStyle:
                                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  RouteStopPreviewSheet(
                routeTitle: currentPlace.routeName.isNotEmpty
                    ? currentPlace.routeNameFor(context.isEn)
                    : context.t('nearby_route_title'),
                routeStats: context
                    .t('stop_of')
                    .replaceAll('{i}', '${_currentStopIndex + 1}')
                    .replaceAll('{n}', '${_filteredPlaces.length}'),
                placeName: currentPlace.nameFor(context.isEn),
                placeDistanceTime: LocationService.formatDistance(
                  LocationService.sortPlacesByDistance(places: [currentPlace], userLocation: _userLocation).first.distanceMeters,
                ),
                placeImageUrl: currentPlace.imageAfterUrl,
                onDetailTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SliderScreen(place: currentPlace),
                    ),
                  );
                },
                onNextStopTap: () {
                  setState(() {
                    _currentStopIndex = (_currentStopIndex + 1) % _filteredPlaces.length;
                  });
                  _mapController.move(
                    _filteredPlaces[_currentStopIndex].location,
                    16.8,
                  );
                },
              ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}