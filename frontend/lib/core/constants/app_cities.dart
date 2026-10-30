/// Şehir seçimi. Şimdilik yalnızca Bursa verisi var; diğerleri "yakında".
class AppCities {
  static const String active = 'Bursa';
  static const List<String> all = [
    'Bursa',
    'İstanbul',
    'Konya',
    'Hatay',
    'Kütahya',
  ];

  static bool isAvailable(String city) => city == active;
}
