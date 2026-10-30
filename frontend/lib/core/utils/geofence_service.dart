import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/heritage_place.dart';
import 'location_service.dart';

/// Kullanıcı bir esere 50 m yaklaştığında haber verir (sunumdaki "konum tetikleyicisi").
/// Her eser, kullanıcı 150 m uzaklaşana kadar yalnızca bir kez tetiklenir.
class GeofenceService {
  static const double radiusMeters = 50;
  static const double resetMeters = 150;
  static const Distance _distance = Distance();

  final Set<String> _inside = {};
  StreamSubscription<Position>? _subscription;

  Future<void> start(
    List<HeritagePlace> places,
    void Function(HeritagePlace place) onEnter,
  ) async {
    await stop();
    // İzin penceresini Ana Sayfa ile aynı istek üzerinden çözer
    await LocationService.getCurrentLocation();
    if (LocationService.lastWasFallback) return;

    final targets = places.where((p) => !p.isSubPlace).toList();
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          final here = LatLng(position.latitude, position.longitude);
          for (final place in targets) {
            final meters = _distance.as(LengthUnit.Meter, here, place.location);
            if (meters <= radiusMeters && _inside.add(place.id)) {
              onEnter(place);
            } else if (meters > resetMeters) {
              _inside.remove(place.id);
            }
          }
        }, onError: (_) {});
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
