import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/heritage_place.dart';
import '../../data/models/place_activity.dart';
import '../../data/repositories/activity_repository.dart';
import '../auth/auth_service.dart';

/// Bursa Pasaportu: tamamlanan görevler ve kazanılan mühürler.
/// Cihazda saklanır; kullanıcı giriş yaptıysa Supabase'deki `user_progress` ile eşlenir.
class Passport extends ChangeNotifier {
  Passport._();
  static final Passport instance = Passport._();

  static const _kActivities = 'pp_activities';
  static const _kStamps = 'pp_stamps';

  final Set<int> _activities = {};
  final Set<String> _stamps = {};

  /// Yeni mühür kazanılınca dolar; ana ekran bunu dinleyip kutlama gösterir.
  final ValueNotifier<HeritagePlace?> ceremony = ValueNotifier(null);

  int get stampCount => _stamps.length;
  bool hasStamp(String placeId) => _stamps.contains(placeId);
  bool isDone(int activityId) =>
      _activities.contains(activityId) ||
      // Mührü zaten kazanılmış eserlerde QR görevi tamamlanmış sayılır (eski ilerleme bozulmasın)
      (activityId < 0 && _stamps.contains('${-activityId}'));

  int doneCount(List<PlaceActivity> list) =>
      list.where((a) => isDone(a.id)).length;

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _activities.addAll((p.getStringList(_kActivities) ?? []).map(int.parse));
      _stamps.addAll(p.getStringList(_kStamps) ?? []);
    } catch (_) {}
    AuthService.changes.listen((s) {
      if (s.event == AuthChangeEvent.signedOut) {
        // Çıkışta bu cihazdaki ilerleme temizlenir (hesapta saklı kalır); sonraki kullanıcıya geçmez.
        _clearLocal();
      } else if (s.session != null) {
        _syncFromServer();
      }
    });
    if (AuthService.isSignedIn) _syncFromServer();
  }

  Future<void> _clearLocal() async {
    _activities.clear();
    _stamps.clear();
    ceremony.value = null;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(
        _kActivities,
        _activities.map((e) => '$e').toList(),
      );
      await p.setStringList(_kStamps, _stamps.toList());
    } catch (_) {}
  }

  /// Görevi işaretler / işareti kaldırır. Eserin tüm görevleri bitince mühür kazanılır.
  void toggleActivity(
    PlaceActivity a,
    HeritagePlace place,
    List<PlaceActivity> all,
  ) {
    final nowDone = _activities.add(a.id);
    if (!nowDone) _activities.remove(a.id);
    _push('activity', a.id, add: nowDone);
    notifyListeners();
    _save();
    if (nowDone && all.every((x) => isDone(x.id))) {
      earnStamp(place);
    }
  }

  /// QR okutuldu: eserin "QR kodunu okut" görevi tamamlanır; tüm görevler bittiyse mühür kazanılır.
  /// Kalan görev sayısını döndürür (mühür kazanıldıysa 0).
  Future<({int done, int total, bool stamped})> completeQr(
    HeritagePlace place,
  ) async {
    final qrId = PlaceActivity.qrIdFor(place.id);
    if (_activities.add(qrId)) {
      _push('activity', qrId, add: true);
      notifyListeners();
      _save();
    }
    final all = await ActivityRepository.forPlace(place.id);
    final done = doneCount(all);
    final complete = done >= all.length;
    final stamped = complete && earnStamp(place);
    return (
      done: done,
      total: all.length,
      stamped: stamped || hasStamp(place.id),
    );
  }

  /// Mührü verir (zaten varsa false döner). Mühür yalnızca eserin tüm görevleri (QR dahil) bitince verilir.
  bool earnStamp(HeritagePlace place) {
    if (!_stamps.add(place.id)) return false;
    _push('stamp', int.tryParse(place.id) ?? 0, add: true);
    notifyListeners();
    _save();
    ceremony.value = place;
    return true;
  }

  Future<void> _push(String kind, int ref, {required bool add}) async {
    final u = AuthService.user;
    if (u == null) return;
    try {
      final t = Supabase.instance.client.from('user_progress');
      if (add) {
        await t.upsert({'user_id': u.id, 'kind': kind, 'ref_id': ref});
      } else {
        await t.delete().match({'user_id': u.id, 'kind': kind, 'ref_id': ref});
      }
    } catch (e) {
      debugPrint('İlerleme senkronu başarısız: $e');
    }
  }

  /// Girişte: sunucudaki ilerlemeyi yerel ile birleştirir, yereldekileri sunucuya gönderir.
  Future<void> _syncFromServer() async {
    final u = AuthService.user;
    if (u == null) return;
    try {
      final c = Supabase.instance.client;
      final rows = await c.from('user_progress').select().eq('user_id', u.id);
      for (final r in rows as List) {
        final id = (r['ref_id'] as num).toInt();
        if (r['kind'] == 'stamp') {
          _stamps.add('$id');
        } else {
          _activities.add(id);
        }
      }
      final upload = [
        ..._activities.map(
          (e) => {'user_id': u.id, 'kind': 'activity', 'ref_id': e},
        ),
        ..._stamps.map(
          (e) => {
            'user_id': u.id,
            'kind': 'stamp',
            'ref_id': int.tryParse(e) ?? 0,
          },
        ),
      ];
      if (upload.isNotEmpty) await c.from('user_progress').upsert(upload);
      notifyListeners();
      _save();
    } catch (e) {
      debugPrint('İlerleme yüklenemedi: $e');
    }
  }
}
