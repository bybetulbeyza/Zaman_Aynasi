import 'package:flutter/foundation.dart';
import '../../data/models/heritage_place.dart';

/// Kullanıcının o anki rotası (hesap gerekmediği için yalnızca bellekte tutulur).
/// Rota oluştur, hazır rota başlat ve "Rotama ekle" bu listeyi besler.
class ActiveRoute extends ChangeNotifier {
  ActiveRoute._();
  static final ActiveRoute instance = ActiveRoute._();

  final List<HeritagePlace> _stops = [];
  String? _titleTr;
  String? _titleEn;

  List<HeritagePlace> get stops => List.unmodifiable(_stops);
  bool get isEmpty => _stops.isEmpty;
  int get length => _stops.length;

  String? titleFor(bool en) => en && (_titleEn?.isNotEmpty ?? false) ? _titleEn : _titleTr;

  bool contains(HeritagePlace place) => _stops.any((p) => p.id == place.id);

  /// Rotayı baştan kurar.
  void setRoute(List<HeritagePlace> stops, {String? titleTr, String? titleEn}) {
    _stops
      ..clear()
      ..addAll(stops);
    _titleTr = titleTr;
    _titleEn = titleEn;
    notifyListeners();
  }

  /// Eseri rotaya ekler. Zaten varsa false döner.
  bool add(HeritagePlace place) {
    if (contains(place)) return false;
    _stops.add(place);
    notifyListeners();
    return true;
  }

  void remove(HeritagePlace place) {
    _stops.removeWhere((p) => p.id == place.id);
    notifyListeners();
  }

  void clear() {
    _stops.clear();
    _titleTr = null;
    _titleEn = null;
    notifyListeners();
  }
}
