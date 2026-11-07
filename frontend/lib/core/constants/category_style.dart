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
        return const CategoryStyle(Color(0xFF0E807A), 'pin_cami');
      case PlaceCategory.han:
        return const CategoryStyle(Color(0xFF7A1C28), 'pin_han');
      case PlaceCategory.hamam:
        return const CategoryStyle(Color(0xFF1E3A8A), 'pin_hamam');
      case PlaceCategory.turbe:
        return const CategoryStyle(Color(0xFF6B7A3A), 'pin_turbe');
      case PlaceCategory.kulliye:
        return const CategoryStyle(Color(0xFF14414F), 'pin_kulliye');
      case PlaceCategory.medrese:
        return const CategoryStyle(Color(0xFF5B4A8B), 'pin_medrese');
      case PlaceCategory.sosyalSivilYapilar:
        return const CategoryStyle(Color(0xFFB8913F), 'pin_sosyal');
    }
  }
}
