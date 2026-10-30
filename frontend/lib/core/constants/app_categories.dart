import '../../data/models/heritage_place.dart';

/// Envanter, Harita ve Rota oluştur ekranlarının ortak kategori listesi.
/// `null` = "Tümü".
class AppCategories {
  static const List<PlaceCategory?> filters = [
    null,
    PlaceCategory.cami,
    PlaceCategory.han,
    PlaceCategory.hamam,
    PlaceCategory.turbe,
    PlaceCategory.kulliye,
    PlaceCategory.sosyalSivilYapilar,
  ];
}
