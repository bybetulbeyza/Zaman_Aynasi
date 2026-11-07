import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Yadigâr'ın "Biliyor muydunuz?" bilgisi (Supabase `yadigar_facts` tablosu).
class YadigarFact {
  final String placeId;
  final String textTr;
  final String textEn;
  final String source;

  const YadigarFact({
    required this.placeId,
    required this.textTr,
    required this.textEn,
    required this.source,
  });

  String textFor(bool en) => en && textEn.isNotEmpty ? textEn : textTr;
}

class YadigarRepository {
  YadigarRepository._();

  static List<YadigarFact>? _cache;
  static DateTime? _cachedAt;

  /// Aktif bilgiler. Tablo yoksa ya da istek başarısızsa boş liste döner;
  /// o durumda Yadigâr eserin kısa açıklamasını gösterir.
  static Future<List<YadigarFact>> facts() async {
    final fresh =
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 10);
    if (_cache != null && fresh) return _cache!;
    try {
      final data = await Supabase.instance.client
          .from('yadigar_facts')
          .select('place_id, text_tr, text_en, source')
          .eq('is_active', true);
      final list = (data as List)
          .map(
            (r) => YadigarFact(
              placeId: '${r['place_id']}',
              textTr: (r['text_tr'] as String? ?? '').trim(),
              textEn: (r['text_en'] as String? ?? '').trim(),
              source: (r['source'] as String? ?? '').trim(),
            ),
          )
          .where((f) => f.textTr.isNotEmpty)
          .toList();
      _cache = list;
      _cachedAt = DateTime.now();
      return list;
    } catch (e) {
      debugPrint('Yadigâr bilgileri alınamadı: $e');
      return _cache ?? const [];
    }
  }
}
