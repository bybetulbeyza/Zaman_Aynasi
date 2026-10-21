import 'package:latlong2/latlong.dart';

enum PlaceCategory { cami, han, hamam, turbe, medrese }

class HeritagePlace {
  final String id;
  final String name;
  final String routeName;
  final PlaceCategory category;
  final LatLng location;
  final String shortDescription;
  final String imageBeforeUrl; // Eski fotoğraf linki
  final String imageAfterUrl;  // Yeni fotoğraf linki

  HeritagePlace({
    required this.id,
    required this.name,
    required this.routeName,
    required this.category,
    required this.location,
    required this.shortDescription,
    required this.imageBeforeUrl,
    required this.imageAfterUrl,
  });

  factory HeritagePlace.fromJson(Map<String, dynamic> json) {
    return HeritagePlace(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      routeName: json['route_name'] ?? 'Han ve Çarşı Hattı',
      category: _parseCategory(json['category']),
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      shortDescription: json['short_description'] ?? '',
      imageBeforeUrl: json['image_before_url'] ?? '',
      imageAfterUrl: json['image_after_url'] ?? '',
    );
  }

  static PlaceCategory _parseCategory(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'cami':
        return PlaceCategory.cami;
      case 'hamam':
        return PlaceCategory.hamam;
      case 'turbe':
        return PlaceCategory.turbe;
      case 'medrese':
        return PlaceCategory.medrese;
      case 'han':
      default:
        return PlaceCategory.han;
    }
  }
}