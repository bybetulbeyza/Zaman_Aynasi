import '../../data/models/heritage_place.dart';
import 'passport.dart';

/// Pasaport unvanı: bir kategorideki tüm eserlerin mührü toplanmışsa o kategorinin unvanı,
/// yoksa toplam mühür sayısına göre bir unvan verilir. Veritabanı gerekmez; mühürler ve
/// eserlerin kategorileri zaten elde.
String passportTitleKey(List<HeritagePlace> places) {
  final total = places.length;
  final n = places.where((p) => Passport.instance.hasStamp(p.id)).length;
  if (total > 0 && n >= total) return 'title_all';

  // En az iki eseri olan bir kategori tamamlandıysa o unvan öne çıkar
  const names = {
    PlaceCategory.han: 'title_han',
    PlaceCategory.cami: 'title_cami',
    PlaceCategory.hamam: 'title_hamam',
    PlaceCategory.turbe: 'title_turbe',
    PlaceCategory.kulliye: 'title_kulliye',
    PlaceCategory.sosyalSivilYapilar: 'title_sosyal',
  };
  for (final e in names.entries) {
    final inCat = places.where((p) => p.category == e.key).toList();
    if (inCat.length >= 2 &&
        inCat.every((p) => Passport.instance.hasStamp(p.id))) {
      return e.value;
    }
  }
  if (n >= 15) return 'title_15';
  if (n >= 10) return 'title_10';
  if (n >= 5) return 'title_5';
  return 'title_new';
}
