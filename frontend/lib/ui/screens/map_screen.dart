import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/heritage_place.dart';
import '../../../data/repositories/heritage_repository.dart';
import '../widgets/map/map_top_search_bar.dart';
import '../widgets/map/route_stop_preview_sheet.dart';
import 'slider_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final HeritageRepository _heritageRepository = HeritageRepository();

  final LatLng _bursaCenter = const LatLng(40.1838, 29.0635);

  List<HeritagePlace> _allPlaces = [];
  List<HeritagePlace> _filteredPlaces = [];
  bool _isLoading = true;
  int _currentStopIndex = 0;

  String _searchQuery = '';
  String _selectedCategory = 'Tümü';

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    final places = await _heritageRepository.getPlaces();
    if (mounted) {
      setState(() {
        _allPlaces = places;
        _applyFilters();
        _isLoading = false;
      });

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

  void _applyFilters() {
    setState(() {
      _filteredPlaces = _allPlaces.where((place) {
        final matchesSearch = place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            place.shortDescription.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCategory = _selectedCategory == 'Tümü' ||
            (place.category.label.toLowerCase().trim() == _selectedCategory.toLowerCase().trim());

        return matchesSearch && matchesCategory;
      }).toList();

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
              const Text(
                'Eserler yüklenemedi.',
                style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchPlaces();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
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

              // Rota Çizgisi
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

              // Numaralı Durak Pinleri
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
              onSearchChanged: (query) {
                _searchQuery = query;
                _applyFilters();
              },
              onFilterSelected: (category) {
                _selectedCategory = category;
                _applyFilters();
              },
              onFilterTap: () {},
            ),
          ),

          // 3. "Yol Tarifi" Hızlı Aksiyon Butonu
          if (currentPlace != null)
            Positioned(
              bottom: 250,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${currentPlace.name} için yol tarifi başlatılıyor...'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation_outlined, size: 16, color: Colors.white),
                label: const Text(
                  'Yol tarifi ↗',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 4,
                ),
              ),
            ),

          // 4. Alt Durak Önizleme Kartı
          if (currentPlace != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RouteStopPreviewSheet(
                routeTitle: currentPlace.routeName.isNotEmpty ? currentPlace.routeName : 'Han ve Çarşı Hattı',
                routeStats: 'Durak ${_currentStopIndex + 1} / ${_filteredPlaces.length} • 3,8 km • 2 sa 30 dk',
                placeName: currentPlace.name,
                placeDistanceTime: '240 m • 3 dk yürüyüş',
                placeImageUrl: currentPlace.imageAfterUrl,
                onDetailTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SliderScreen(
                        title: currentPlace.name,
                        beforeImageUrl: currentPlace.imageBeforeUrl,
                        afterImageUrl: currentPlace.imageAfterUrl,
                        description: currentPlace.shortDescription,
                        hotspots: currentPlace.hotspots,
                      ),
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
            ),
        ],
      ),
    );
  }
}