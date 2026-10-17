import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/heritage_place.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Bursa Tarihi Çarşı & Hanlar Bölgesi odaklı başlangıç noktası
  final LatLng _bursaCenter = const LatLng(40.1834, 29.0630);

  // Örnek pilot bölge eserleri
  final List<HeritagePlace> _places = [
    HeritagePlace(
      id: '1',
      name: 'Ulu Cami',
      category: PlaceCategory.cami,
      location: const LatLng(40.1834, 29.0630),
      shortDescription: '1399 yılında I. Bayezid tarafından yaptırılan ulu mabet.',
    ),
    HeritagePlace(
      id: '2',
      name: 'Koza Han',
      category: PlaceCategory.han,
      location: const LatLng(40.1842, 29.0645),
      shortDescription: 'İpek yolu ticaretinin kalbi, tarihi ipek pazarı.',
    ),
    HeritagePlace(
      id: '3',
      name: 'Yeşil Türbe',
      category: PlaceCategory.turbe,
      location: const LatLng(40.1816, 29.0747),
      shortDescription: 'Bursa\'nın simgesi olan çinileriyle ünlü anıt yapı.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Zaman Aynası - Keşif Haritası',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A), // Vakıf / Gece Laciverti
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _bursaCenter,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.zamanaynasi.app',
          ),
          MarkerLayer(
            markers: _places.map((place) {
              return Marker(
                point: place.location,
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () {
                    // Pine tıklandığında mini bilgi snackbar'ı göster
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${place.name} seçildi'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: place.categoryColor,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: place.categoryColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      place.categoryIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}