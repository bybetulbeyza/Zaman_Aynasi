import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/heritage_place.dart';

class LocationService {
  // Varsayılan Merkez: Bursa Tarihi Kent Merkezi (Ulu Cami / Heykel civarı)
  static const LatLng defaultCenter = LatLng(40.1838, 29.0635);
  static const Distance _distanceCalculator = Distance();

  // Kullanıcının anlık koordinatını döner.
  // İzin verilmezse veya servis kapalıysa defaultCenter döner.
  static Future<LatLng> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return defaultCenter;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return defaultCenter;
      }

      if (permission == LocationPermission.deniedForever) return defaultCenter;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return defaultCenter;
    }
  }

  // Verilen eser listesini belirtilen konuma olan mesafesine göre
  // en yakından en uzağa sıralar ve her eserin `distanceMeters` alanını doldurur.
  static List<HeritagePlace> sortPlacesByDistance({
    required List<HeritagePlace> places,
    required LatLng userLocation,
  }) {
    final updatedList = places.map((place) {
      final meters = _distanceCalculator.as(
        LengthUnit.Meter,
        userLocation,
        place.location,
      );
      return place.copyWithDistance(meters);
    }).toList();

    updatedList.sort((a, b) {
      final distA = a.distanceMeters ?? double.infinity;
      final distB = b.distanceMeters ?? double.infinity;
      return distA.compareTo(distB);
    });

    return updatedList;
  }

  /// Nearest Neighbor (TSP Sezgisel Algoritması):
  /// Durakları rastgele veya ID sırasına göre değil, mantıklı bir yürüyüş hattı
  /// oluşturacak şekilde en yakından başlayarak birbirine bağlar.
  static List<HeritagePlace> optimizeRouteOrder({
    required List<HeritagePlace> places,
    required LatLng startLocation,
  }) {
    if (places.length <= 2) return places;

    final unvisited = List<HeritagePlace>.from(places);
    final optimized = <HeritagePlace>[];
    LatLng currentPoint = startLocation;

    while (unvisited.isNotEmpty) {
      int nearestIndex = 0;
      double shortestDist = double.infinity;

      for (int i = 0; i < unvisited.length; i++) {
        final dist = _distanceCalculator.as(
          LengthUnit.Meter,
          currentPoint,
          unvisited[i].location,
        );
        if (dist < shortestDist) {
          shortestDist = dist;
          nearestIndex = i;
        }
      }

      final nextPlace = unvisited.removeAt(nearestIndex);
      optimized.add(nextPlace);
      currentPoint = nextPlace.location; // Sıradaki durak referans noktası olur
    }

    return optimized;
  }

  // Metreyi ekrana uygun metne dönüştürür (örn: "250 m" veya "1.4 km")
  static String formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}