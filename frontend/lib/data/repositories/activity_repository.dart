import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place_activity.dart';

class ActivityRepository {
  static Map<String, List<PlaceActivity>>? _cache;
  static DateTime? _cachedAt;

  /// Tüm görevler tek istekte çekilir ve birkaç dakika bellekte tutulur.
  static Future<Map<String, List<PlaceActivity>>> _all() async {
    final fresh =
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 5);
    if (_cache != null && fresh) return _cache!;
    try {
      final data = await Supabase.instance.client
          .from('place_activities')
          .select()
          .order('sort_order', ascending: true);
      final map = <String, List<PlaceActivity>>{};
      for (final row in data as List) {
        final a = PlaceActivity.fromJson(row as Map<String, dynamic>);
        map.putIfAbsent(a.placeId, () => []).add(a);
      }
      _cache = map;
      _cachedAt = DateTime.now();
      return map;
    } catch (e) {
      debugPrint('Görevler çekilemedi: $e');
      return _cache ?? {};
    }
  }

  static Future<List<PlaceActivity>> forPlace(String placeId) async =>
      (await _all())[placeId] ?? const [];
}
