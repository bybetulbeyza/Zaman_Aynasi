import 'package:latlong2/latlong.dart';

enum PlaceCategory {
  cami,
  han,
  hamam,
  turbe,
  kulliye,
  sosyalSivilYapilar;

  String labelFor(bool en) {
    if (!en) return label;
    switch (this) {
      case PlaceCategory.cami:
        return 'Mosque';
      case PlaceCategory.han:
        return 'Inn';
      case PlaceCategory.hamam:
        return 'Bathhouse';
      case PlaceCategory.turbe:
        return 'Tomb';
      case PlaceCategory.kulliye:
        return 'Complex';
      case PlaceCategory.sosyalSivilYapilar:
        return 'Social & Civil';
    }
  }

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
  final String titleEn;
  final String descriptionEn;
  final String? aiVideoEnUrl;
  final String?
  aiVideoUrl; // Supabase: ai_video (boşsa 'AI hikâyesi' butonu gizlenir)
  final String?
  targetPlaceId; // Külliyeden alt yapıya (Türbe, Hamam vb.) geçiş ID'si

  Hotspot({
    required this.id,
    required this.placeId,
    required this.title,
    required this.description,
    required this.targetSide,
    required this.xPercent,
    required this.yPercent,
    this.titleEn = '',
    this.descriptionEn = '',
    this.aiVideoEnUrl,
    this.aiVideoUrl,
    this.targetPlaceId,
  });

  String titleFor(bool en) => en && titleEn.isNotEmpty ? titleEn : title;
  String descriptionFor(bool en) =>
      en && descriptionEn.isNotEmpty ? descriptionEn : description;

  /// Dile göre AI videosu; İngilizce yoksa Türkçeye döner. Hiçbiri yoksa null.
  String? videoFor(bool en) {
    final enUrl = aiVideoEnUrl?.trim() ?? '';
    final trUrl = aiVideoUrl?.trim() ?? '';
    if (en && enUrl.isNotEmpty) return enUrl;
    return trUrl.isNotEmpty ? trUrl : (enUrl.isNotEmpty ? enUrl : null);
  }

  bool get hasAiVideo => aiVideoUrl != null && aiVideoUrl!.trim().isNotEmpty;

  bool get hasSubPlaceNavigation =>
      targetPlaceId != null && targetPlaceId!.isNotEmpty;

  factory Hotspot.fromJson(Map<String, dynamic> json) {
    return Hotspot(
      id: json['id'],
      placeId: json['place_id'],
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetSide: (json['target_side'] as String?)?.toLowerCase() ?? 'after',
      xPercent: (json['x_percent'] as num?)?.toDouble() ?? 0.0,
      yPercent: (json['y_percent'] as num?)?.toDouble() ?? 0.0,
      titleEn: (json['title_en'] as String? ?? '').trim(),
      descriptionEn: (json['description_en'] as String? ?? '').trim(),
      aiVideoEnUrl: (json['ai_video_en'] as String?)?.trim(),
      aiVideoUrl: (json['ai_video'] as String?)?.trim(),
      targetPlaceId: json['target_place_id']?.toString(),
    );
  }
}

class HeritagePlace {
  final String id;
  final String? parentId; // Külliyenin alt parçası ise üst yapının ID'si
  final String name;

  /// Supabase: city — eserin şehri (boşsa aktif şehir sayılır).
  final String city;
  final String routeName;
  final PlaceCategory category;
  final LatLng location;
  final String shortDescription;
  final String imageBeforeUrl;
  final String imageAfterUrl;
  final bool isFeatured;
  final String constructionDate; // Supabase: construction_date
  final String architect; // Supabase: architect
  final String patron; // Supabase: patron (Bani)
  final String
  inventoryLocation; // Supabase: inventory_location (örn. 'Cilt 1, s. 37')
  final String nameEn;
  final String shortDescriptionEn;
  final String routeNameEn;
  final String audioGuideEnUrl;
  final String aiVideoEnUrl;
  final String aiVideoUrl; // Supabase: ai_video (tarihî dönüşüm videosu)
  final String
  audioGuideUrl; // Supabase: audio_guide (sesli rehber ses dosyası)
  final String
  qrUrl; // Supabase: qr_url (QR görselinin adresi; QR içeriği 'eser:<id>')
  final List<Hotspot> hotspots;

  /// Supabase: old_photos — eski fotoğraf adresleri (liste ya da boşluk/virgülle ayrılmış metin).
  final List<String> oldPhotos;
  final double? distanceMeters;

  HeritagePlace({
    required this.id,
    this.parentId,
    required this.name,
    this.city = 'Bursa',
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
    this.nameEn = '',
    this.shortDescriptionEn = '',
    this.routeNameEn = '',
    this.audioGuideEnUrl = '',
    this.aiVideoEnUrl = '',
    this.aiVideoUrl = '',
    this.audioGuideUrl = '',
    this.qrUrl = '',
    this.oldPhotos = const [],
    this.hotspots = const [],
    this.distanceMeters,
  });

  // Harita ve genel rotalarda alt yapıyı gizlemek için kontrol
  bool get isSubPlace => parentId != null && parentId!.isNotEmpty;

  String nameFor(bool en) => en && nameEn.isNotEmpty ? nameEn : name;
  String descriptionFor(bool en) => en && shortDescriptionEn.isNotEmpty
      ? shortDescriptionEn
      : shortDescription;
  String routeNameFor(bool en) =>
      en && routeNameEn.isNotEmpty ? routeNameEn : routeName;

  /// Dile göre sesli rehber adresi; İngilizce yoksa Türkçeye döner.
  String audioFor(bool en) =>
      en && audioGuideEnUrl.isNotEmpty ? audioGuideEnUrl : audioGuideUrl;

  /// Dile göre AI videosu adresi; İngilizce yoksa Türkçeye döner.
  String videoFor(bool en) =>
      en && aiVideoEnUrl.isNotEmpty ? aiVideoEnUrl : aiVideoUrl;

  bool get hasAiVideo => aiVideoUrl.isNotEmpty || aiVideoEnUrl.isNotEmpty;
  bool get hasAudioGuide => audioGuideUrl.isNotEmpty;

  // SliderScreen ile tam geriye dönük uyumluluk
  String get period => constructionDate;

  HeritagePlace copyWithDistance(double distance) {
    return HeritagePlace(
      id: id,
      parentId: parentId,
      name: name,
      city: city,
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
      nameEn: nameEn,
      shortDescriptionEn: shortDescriptionEn,
      routeNameEn: routeNameEn,
      audioGuideEnUrl: audioGuideEnUrl,
      aiVideoEnUrl: aiVideoEnUrl,
      aiVideoUrl: aiVideoUrl,
      audioGuideUrl: audioGuideUrl,
      qrUrl: qrUrl,
      oldPhotos: oldPhotos,
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
      city: (json['city'] as String? ?? '').trim().isEmpty
          ? 'Bursa'
          : (json['city'] as String).trim(),
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
      constructionDate:
          ((json['construction_date'] ?? json['period']) as String? ?? '')
              .trim(),
      architect: (json['architect'] as String? ?? '').trim(),
      patron: (json['patron'] as String? ?? '').trim(),
      inventoryLocation: (json['inventory_location'] as String? ?? '').trim(),
      nameEn: (json['name_en'] as String? ?? '').trim(),
      shortDescriptionEn: (json['short_description_en'] as String? ?? '')
          .trim(),
      routeNameEn: (json['route_name_en'] as String? ?? '').trim(),
      audioGuideEnUrl: (json['audio_guide_en'] as String? ?? '').trim(),
      aiVideoEnUrl: (json['ai_video_en'] as String? ?? '').trim(),
      aiVideoUrl: (json['ai_video'] as String? ?? '').trim(),
      audioGuideUrl: (json['audio_guide'] as String? ?? '').trim(),
      qrUrl: json['qr_url'] as String? ?? '',
      oldPhotos: _parsePhotos(json['old_photos']),
      hotspots: parsedHotspots,
    );
  }

  /// `old_photos` bir dizi ya da "url1, url2 ..." biçiminde metin olabilir; ikisini de kabul eder.
  static List<String> _parsePhotos(dynamic raw) {
    final items = raw is List
        ? raw.map((e) => e.toString())
        : raw is String
        ? raw.split(RegExp(r'[\s,;]+'))
        : const <String>[];
    return items
        .map((e) => e.trim().replaceAll(RegExp(r'^[{"]+|[}"]+$'), ''))
        .where((e) => e.startsWith('http'))
        .toList();
  }

  static PlaceCategory _parseCategory(String? cat) {
    final normalized = cat?.toLowerCase().trim() ?? '';
    if (normalized.contains('sosyal') || normalized.contains('sivil')) {
      return PlaceCategory.sosyalSivilYapilar;
    } else if (normalized.contains('külliye') ||
        normalized.contains('kulliye')) {
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
