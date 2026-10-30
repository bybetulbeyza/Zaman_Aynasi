import 'dart:ui';
import '../../data/models/heritage_place.dart';

/// Kategoriye özel renk ve ikon (harita pinleri, etiketler). Tema paletinden seçilmiştir.
class CategoryStyle {
  final Color color;
  final String icon; // assets/icons/<icon>.png

  const CategoryStyle(this.color, this.icon);

  static CategoryStyle of(PlaceCategory c) {
    switch (c) {
      case PlaceCategory.cami:
        return const CategoryStyle(Color(0xFF0E807A), 'cat_cami');
      case PlaceCategory.han:
        return const CategoryStyle(Color(0xFF7A1C28), 'cat_han');
      case PlaceCategory.hamam:
        return const CategoryStyle(Color(0xFF1E3A8A), 'cat_hamam');
      case PlaceCategory.turbe:
        return const CategoryStyle(Color(0xFF6B7A3A), 'cat_turbe');
      case PlaceCategory.kulliye:
        return const CategoryStyle(Color(0xFF14414F), 'cat_kulliye');
      case PlaceCategory.sosyalSivilYapilar:
        return const CategoryStyle(Color(0xFFB8913F), 'cat_sosyal');
    }
  }
}
