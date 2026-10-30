/// Harita karo kaynağı. Mapbox jetonu koda gömülmez:
/// `flutter run --dart-define-from-file=env.json` ile verilir. Jeton yoksa OpenStreetMap kullanılır.
class MapConfig {
  static const String mapboxToken = String.fromEnvironment('MAPBOX_TOKEN');
  static const String mapboxStyle = String.fromEnvironment(
    'MAPBOX_STYLE',
    defaultValue: 'mehtapaslan/cmvvk87wx000y01s8524xau31',
  );

  static bool get useMapbox => mapboxToken.isNotEmpty;

  static String get tileUrl => useMapbox
      ? 'https://api.mapbox.com/styles/v1/$mapboxStyle/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// @2x karolar 256 px boyutunda gösterilir.
  static double get tileSize => useMapbox ? 512 : 256;
  static double get zoomOffset => useMapbox ? -1 : 0;
}
