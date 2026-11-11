import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Yadigâr'ın animasyon klipleri. Her klip `assets/yadigar/` altında tek bir sprite atlası:
/// 176×256 piksellik kareler, satır başına 10 kare, saniyede 12 kare.
/// Kareler videolardan çıkarıldı: pembe fon kaldırıldı, bütün kliplerde karakterin boyu
/// ve ayak hizası eşitlendi (sevinçteki zıplama korunur).
enum YadigarClip {
  greet('greet', 48),
  idle('idle', 48),
  lookUp('lookup', 49),
  celebrate('celebrate', 62),
  paperTake('paper_take', 58),
  paperRead('paper_read', 38);

  const YadigarClip(this.file, this.frames);
  final String file;
  final int frames;

  String get asset => 'assets/yadigar/yadigar_$file.webp';
}

class YadigarSprites {
  YadigarSprites._();

  static const double frameW = 176;
  static const double frameH = 256;
  static const int cols = 10;
  static const double fps = 12;

  /// Kâğıt çıkarma klibinde kâğıdın açıldığı kare; bilgi kartı bu karede açılır.
  static const int paperOpenFrame = 44;

  /// Aynı anda bellekte tutulan en fazla atlas sayısı (bekleme hep tutulur).
  /// Bir atlas çözülmüş hâlde yaklaşık 7–13 MB yer kaplar.
  static const int _maxCached = 3;

  static final Map<YadigarClip, ui.Image> _cache = {};
  static final Map<YadigarClip, Future<ui.Image>> _loading = {};
  static final List<YadigarClip> _recent = [];

  /// Atlasın bir kopyasını verir; çağıran işi bitince `dispose()` eder.
  /// Önbellekten düşen atlas, kopyaları kullanılırken bellekte kalır ve son kopya
  /// bırakılınca serbest kalır.
  static Future<ui.Image> load(YadigarClip clip) async {
    final hit = _cache[clip];
    if (hit != null) {
      _touch(clip);
      return hit.clone();
    }
    final img = await (_loading[clip] ??= _decode(clip));
    _loading.remove(clip);
    if (!_cache.containsKey(clip)) {
      _cache[clip] = img;
      _touch(clip);
      _evict();
    }
    return _cache[clip]!.clone();
  }

  static Future<ui.Image> _decode(YadigarClip clip) async {
    final data = await rootBundle.load(clip.asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static void _touch(YadigarClip clip) {
    _recent
      ..remove(clip)
      ..add(clip);
  }

  static void _evict() {
    while (_cache.length > _maxCached) {
      final old = _recent.firstWhere(
        (c) => c != YadigarClip.idle && _cache.containsKey(c),
        orElse: () => YadigarClip.idle,
      );
      if (old == YadigarClip.idle) break;
      _recent.remove(old);
      _cache.remove(old)?.dispose();
    }
  }

  /// [index]. karenin atlas içindeki yeri.
  static Rect frameRect(int index) => Rect.fromLTWH(
    (index % cols) * frameW,
    (index ~/ cols) * frameH,
    frameW,
    frameH,
  );
}
