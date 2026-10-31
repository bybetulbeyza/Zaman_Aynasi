import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/heritage_place.dart';

class HeritageRepository {
  final SupabaseClient _client = Supabase.instance.client;

  static List<HeritagePlace>? _cache;
  static DateTime? _cachedAt;

  /// Birkaç dakika bellekte tutulan liste (bağlı eserleri bulmak için tekrar tekrar istek atmamak).
  Future<List<HeritagePlace>> getPlacesCached() async {
    final fresh =
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 3);
    if (_cache != null && fresh) return _cache!;
    final places = await getPlaces();
    if (places.isNotEmpty) {
      _cache = places;
      _cachedAt = DateTime.now();
    }
    return places;
  }

  Future<List<HeritagePlace>> getPlaces() async {
    try {
      final data = await _client
          .from('heritage_places')
          .select('*, Hotspots(*)')
          .order('id', ascending: true);

      return (data as List)
          .map((item) => HeritagePlace.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Supabase veri çekme hatası: $e');
      return [];
    }
  }
}
