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

  List<HeritagePlace> _routePlaces = [];
  bool _isLoading = true;
  int _currentStopIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    final places = await _heritageRepository.getPlaces();
    if (mounted) {
      setState(() {
        _routePlaces = places;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.leafGreen),
        ),
      );
    }

    if (_routePlaces.isEmpty) {
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.leafGreen),
                child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final currentPlace = _routePlaces[_currentStopIndex];
    final List<LatLng> routePoints = _routePlaces.map((p) => p.location).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          // 1. Harita Katmanı
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _routePlaces.isNotEmpty ? _routePlaces.first.location : _bursaCenter,
              initialZoom: 16.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zamanaynasi.app',
              ),

              // Zümrüt Yeşili Rota Çizgisi
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4.5,
                    color: AppColors.leafGreen,
                  ),
                ],
              ),

              // Numaralı Durak Pinleri (1, 2, 3...)
              MarkerLayer(
                markers: List.generate(_routePlaces.length, (index) {
                  final place = _routePlaces[index];
                  final isSelected = index == _currentStopIndex;

                  return Marker(
                    point: place.location,
                    width: isSelected ? 42 : 34,
                    height: isSelected ? 42 : 34,
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
                              ? const Color(0xFFC59F60)
                              : AppColors.leafGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: MapTopSearchBar(
              onSearchChanged: (query) {},
              onFilterSelected: (category) {},
            ),
          ),

          // 3. "Yol Tarifi" Hızlı Aksiyon Butonu
          Positioned(
            bottom: 245,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${currentPlace.name} için rota hesaplanıyor...'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.navigation_outlined, size: 16, color: Colors.white),
              label: const Text(
                'Yol tarifi ↗',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leafGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 3,
              ),
            ),
          ),

          // 4. Alt Durak Önizleme Kartı
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RouteStopPreviewSheet(
              routeTitle: currentPlace.routeName,
              routeStats: 'Durak ${_currentStopIndex + 1} / ${_routePlaces.length} • 2,4 km • 1 sa 15 dk',
              placeName: currentPlace.name,
              placeDistanceTime: '240 m • 3 dk yürüyüş',
              placeImageUrl: currentPlace.imageAfterUrl,
              onDetailTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SliderScreen(
                      title: currentPlace.name,
                      beforeImageUrl: currentPlace.imageBeforeUrl, // Eski (Sol)
                      afterImageUrl: currentPlace.imageAfterUrl,   // Yeni (Sağ)
                      description: currentPlace.shortDescription,
                    ),
                  ),
                );
              },
              onNextStopTap: () {
                setState(() {
                  _currentStopIndex = (_currentStopIndex + 1) % _routePlaces.length;
                });
                _mapController.move(
                  _routePlaces[_currentStopIndex].location,
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