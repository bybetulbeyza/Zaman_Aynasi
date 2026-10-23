import 'package:latlong2/latlong.dart';

enum PlaceCategory {
  cami,
  han,
  hamam,
  turbe,
  kulliye,
  sosyalSivilYapilar;

  String get label {
    switch (this) {
      case PlaceCategory.cami:
        return 'Cami';
      case PlaceCategory.han:
        return 'Han';
      case PlaceCategory.hamam:
        return 'Hamam';
      case PlaceCategory.turbe:
        return 'Türbe';
      case PlaceCategory.kulliye:
        return 'Külliye';
      case PlaceCategory.sosyalSivilYapilar:
        return 'Sosyal & Sivil Yapılar';
    }
  }
}

class Hotspot {
  final dynamic id;
  final dynamic placeId;
  final String title;
  final String description;
  final String targetSide;
  final double xPercent;
  final double yPercent;

  Hotspot({
    required this.id,
    required this.placeId,
    required this.title,
    required this.description,
    required this.targetSide,
    required this.xPercent,
    required this.yPercent,
  });

  factory Hotspot.fromJson(Map<String, dynamic> json) {
    return Hotspot(
      id: json['id'],
      placeId: json['place_id'],
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetSide: (json['target_side'] as String?)?.toLowerCase() ?? 'after',
      xPercent: (json['x_percent'] as num?)?.toDouble() ?? 0.0,
      yPercent: (json['y_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HeritagePlace {
  final String id;
  final String name;
  final String routeName;
  final PlaceCategory category;
  final LatLng location;
  final String shortDescription;
  final String imageBeforeUrl;
  final String imageAfterUrl;
  final List<Hotspot> hotspots;

  HeritagePlace({
    required this.id,
    required this.name,
    required this.routeName,
    required this.category,
    required this.location,
    required this.shortDescription,
    required this.imageBeforeUrl,
    required this.imageAfterUrl,
    this.hotspots = const [],
  });

  factory HeritagePlace.fromJson(Map<String, dynamic> json) {
    final rawHotspots = json['Hotspots'] ?? json['hotspots'];
    List<Hotspot> parsedHotspots = [];

    if (rawHotspots is List) {
      parsedHotspots = rawHotspots
          .map((item) => Hotspot.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return HeritagePlace(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      routeName: json['route_name'] as String? ?? '',
      category: _parseCategory(json['category'] as String?),
      location: LatLng(
        (json['latitude'] as num?)?.toDouble() ?? 0.0,
        (json['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      shortDescription: json['short_description'] as String? ?? '',
      imageBeforeUrl: json['image_before_url'] as String? ?? '',
      imageAfterUrl: json['image_after_url'] as String? ?? '',
      hotspots: parsedHotspots,
    );
  }

  static PlaceCategory _parseCategory(String? cat) {
    final normalized = cat?.toLowerCase().trim() ?? '';
    if (normalized.contains('sosyal') || normalized.contains('sivil')) {
      return PlaceCategory.sosyalSivilYapilar;
    } else if (normalized.contains('külliye') || normalized.contains('kulliye')) {
      return PlaceCategory.kulliye;
    } else if (normalized.contains('cami')) {
      return PlaceCategory.cami;
    } else if (normalized.contains('hamam')) {
      return PlaceCategory.hamam;
    } else if (normalized.contains('türbe') || normalized.contains('turbe')) {
      return PlaceCategory.turbe;
    } else {
      return PlaceCategory.han;
    }
  }
}