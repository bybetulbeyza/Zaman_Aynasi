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
  final String? aiVideoUrl; // Supabase: ai_video (boşsa 'AI hikâyesi' butonu gizlenir)
  final String? targetPlaceId; // Külliyeden alt yapıya (Türbe, Hamam vb.) geçiş ID'si

  Hotspot({
    required this.id,
    required this.placeId,
    required this.title,
    required this.description,
    required this.targetSide,
    required this.xPercent,
    required this.yPercent,
    this.aiVideoUrl,
    this.targetPlaceId,
  });

  bool get hasAiVideo => aiVideoUrl != null && aiVideoUrl!.trim().isNotEmpty;

  bool get hasSubPlaceNavigation => targetPlaceId != null && targetPlaceId!.isNotEmpty;

  factory Hotspot.fromJson(Map<String, dynamic> json) {
    return Hotspot(
      id: json['id'],
      placeId: json['place_id'],
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetSide: (json['target_side'] as String?)?.toLowerCase() ?? 'after',
      xPercent: (json['x_percent'] as num?)?.toDouble() ?? 0.0,
      yPercent: (json['y_percent'] as num?)?.toDouble() ?? 0.0,
      aiVideoUrl: (json['ai_video'] as String?)?.trim(),
      targetPlaceId: json['target_place_id']?.toString(),
    );
  }
}

class HeritagePlace {
  final String id;
  final String? parentId; // Külliyenin alt parçası ise üst yapının ID'si
  final String name;
  final String routeName;
  final PlaceCategory category;
  final LatLng location;
  final String shortDescription;
  final String imageBeforeUrl;
  final String imageAfterUrl;
  final bool isFeatured;
  final String constructionDate; // Supabase: construction_date
  final String architect;        // Supabase: architect
  final String patron;           // Supabase: patron (Bani)
  final String inventoryLocation;// Supabase: inventory_location (örn. 'Cilt 1, s. 37')
  final String aiVideoUrl;       // Supabase: ai_video (tarihî dönüşüm videosu)
  final String audioGuideUrl;    // Supabase: audio_guide (sesli rehber ses dosyası)
  final String qrUrl;            // Supabase: qr_url (QR görselinin adresi; QR içeriği 'eser:<id>')
  final List<Hotspot> hotspots;
  final double? distanceMeters;

  HeritagePlace({
    required this.id,
    this.parentId,
    required this.name,
    required this.routeName,
    required this.category,
    required this.location,
    required this.shortDescription,
    required this.imageBeforeUrl,
    required this.imageAfterUrl,
    this.isFeatured = false,
    this.constructionDate = '',
    this.architect = '',
    this.patron = '',
    this.inventoryLocation = '',
    this.aiVideoUrl = '',
    this.audioGuideUrl = '',
    this.qrUrl = '',
    this.hotspots = const [],
    this.distanceMeters,
  });

  // Harita ve genel rotalarda alt yapıyı gizlemek için kontrol
  bool get isSubPlace => parentId != null && parentId!.isNotEmpty;

  bool get hasAiVideo => aiVideoUrl.isNotEmpty;
  bool get hasAudioGuide => audioGuideUrl.isNotEmpty;

  // SliderScreen ile tam geriye dönük uyumluluk
  String get period => constructionDate;

  HeritagePlace copyWithDistance(double distance) {
    return HeritagePlace(
      id: id,
      parentId: parentId,
      name: name,
      routeName: routeName,
      category: category,
      location: location,
      shortDescription: shortDescription,
      imageBeforeUrl: imageBeforeUrl,
      imageAfterUrl: imageAfterUrl,
      isFeatured: isFeatured,
      constructionDate: constructionDate,
      architect: architect,
      patron: patron,
      inventoryLocation: inventoryLocation,
      aiVideoUrl: aiVideoUrl,
      audioGuideUrl: audioGuideUrl,
      qrUrl: qrUrl,
      hotspots: hotspots,
      distanceMeters: distance,
    );
  }

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
      parentId: json['parent_id']?.toString(),
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
      isFeatured: json['is_featured'] as bool? ?? false,
      constructionDate: ((json['construction_date'] ?? json['period']) as String? ?? '').trim(),
      architect: (json['architect'] as String? ?? '').trim(),
      patron: (json['patron'] as String? ?? '').trim(),
      inventoryLocation: (json['inventory_location'] as String? ?? '').trim(),
      aiVideoUrl: (json['ai_video'] as String? ?? '').trim(),
      audioGuideUrl: (json['audio_guide'] as String? ?? '').trim(),
      qrUrl: json['qr_url'] as String? ?? '',
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