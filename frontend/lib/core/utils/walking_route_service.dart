import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/map_config.dart';

/// Mapbox yürüyüş yolu: sokakları izleyen hat, gerçek mesafe ve süre.
class WalkingRoute {
  final List<LatLng> points;
  final double meters;
  final double seconds;
  const WalkingRoute(this.points, this.meters, this.seconds);

  String get distanceLabel => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  int get minutes => (seconds / 60).round();
}

class WalkingRouteService {
  static final Map<String, WalkingRoute> _cache = {};

  /// Jeton yoksa, 2'den az / 25'ten çok durak varsa ya da istek başarısızsa null döner
  /// (çağıran taraf düz çizgiye düşer).
  static Future<WalkingRoute?> fetch(List<LatLng> stops) async {
    if (!MapConfig.useMapbox || stops.length < 2 || stops.length > 25)
      return null;
    final coords = stops.map((p) => '${p.longitude},${p.latitude}').join(';');
    final cached = _cache[coords];
    if (cached != null) return cached;
    try {
      final uri = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/walking/$coords'
        '?geometries=geojson&overview=full&access_token=${MapConfig.mapboxToken}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final route =
          (jsonDecode(res.body)['routes'] as List).first
              as Map<String, dynamic>;
      final pts = (route['geometry']['coordinates'] as List)
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
      final result = WalkingRoute(
        pts,
        (route['distance'] as num).toDouble(),
        (route['duration'] as num).toDouble(),
      );
      _cache[coords] = result;
      return result;
    } catch (e) {
      debugPrint('Yürüyüş rotası alınamadı: $e');
      return null;
    }
  }
}
