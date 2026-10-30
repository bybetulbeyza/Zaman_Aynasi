import 'package:latlong2/latlong.dart';
import 'heritage_place.dart';

/// Aynı `route_name` değerini paylaşan eserlerden oluşan hazır rota.
class HeritageRoute {
  static const Distance _distance = Distance();
  static const double _walkKmPerHour = 4.5;
  static const int _minutesPerStop = 15;

  final String name;
  final String nameEn;
  final List<HeritagePlace> stops;
  final double distanceKm;
  final int durationMinutes;

  const HeritageRoute({
    required this.name,
    this.nameEn = '',
    required this.stops,
    required this.distanceKm,
    required this.durationMinutes,
  });

  String nameFor(bool en) => en && nameEn.isNotEmpty ? nameEn : name;

  String get distanceLabel => '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';

  String get durationLabel {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '$m dk';
    if (m == 0) return '$h sa';
    return '$h sa $m dk';
  }

  String distanceLabelFor(bool en) => en ? distanceLabel.replaceAll(',', '.') : distanceLabel;

  String durationLabelFor(bool en) {
    if (!en) return durationLabel;
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h hr';
    return '$h hr $m min';
  }

  /// Eserleri `route_name`'e göre gruplar; duraklar yürüyüş sırasına dizilir.
  static List<HeritageRoute> fromPlaces(List<HeritagePlace> places) {
    final groups = <String, List<HeritagePlace>>{};
    for (final p in places) {
      final name = p.routeName.trim();
      if (name.isEmpty || p.isSubPlace) continue;
      groups.putIfAbsent(name, () => []).add(p);
    }

    return groups.entries.map((e) => _build(e.key, e.value)).toList();
  }

  static HeritageRoute _build(String name, List<HeritagePlace> places) {
    // En yakın komşu sırası, ilk eserden başlar
    final remaining = [...places];
    final ordered = <HeritagePlace>[remaining.removeAt(0)];
    while (remaining.isNotEmpty) {
      final last = ordered.last.location;
      remaining.sort((a, b) => _distance
          .as(LengthUnit.Meter, last, a.location)
          .compareTo(_distance.as(LengthUnit.Meter, last, b.location)));
      ordered.add(remaining.removeAt(0));
    }

    double meters = 0;
    for (var i = 1; i < ordered.length; i++) {
      meters += _distance.as(LengthUnit.Meter, ordered[i - 1].location, ordered[i].location);
    }
    final km = meters / 1000;
    final raw = (km / _walkKmPerHour * 60).round() + ordered.length * _minutesPerStop;
    final minutes = (raw / 5).round() * 5;

    return HeritageRoute(
        name: name,
        nameEn: ordered.map((p) => p.routeNameEn).firstWhere((n) => n.isNotEmpty, orElse: () => ''),
        stops: ordered, distanceKm: km, durationMinutes: minutes);
  }
}
