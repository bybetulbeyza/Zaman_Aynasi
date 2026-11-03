import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../core/l10n/app_lang.dart';

/// Altyazı açık/kapalı tercihi (hatırlanır; varsayılan açık).
class SubtitlePrefs extends ChangeNotifier {
  SubtitlePrefs._();
  static final SubtitlePrefs instance = SubtitlePrefs._();

  bool _on = true;
  bool _loaded = false;
  bool get on => _on;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      _on = p.getBool('subtitles_on') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggle() async {
    _on = !_on;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('subtitles_on', _on);
    } catch (_) {}
  }
}

/// Altyazı parçası: başlangıç saniyesi ve metni.
class SubtitleCue {
  final double start;
  final String text;
  const SubtitleCue(this.start, this.text);
}

/// Anlatım metnini cümlelere böler, her parçaya metin uzunluğuna orantılı bir süre verir.
/// Metinde zaman bilgisi olmadığı için eşleşme yaklaşıktır; konuşmanın başındaki ve sonundaki
/// kısa sessizlikler için baştan/sondan pay bırakılır.
List<SubtitleCue> buildSubtitleCues(String script, double totalSec) {
  final clean = script
      .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (clean.isEmpty || totalSec <= 0) return const [];
  // Cümle sonları: "M. 1549", "II. Murad" gibi kısaltma ve Romen rakamlarından sonra bölünmez
  final sentences = <String>[];
  var current = <String>[];
  for (final token in clean.split(' ')) {
    current.add(token);
    if (RegExp(r'[.!?…]$').hasMatch(token)) {
      final bare = token.replaceAll(RegExp(r'[.!?…]+$'), '');
      final isAbbrev =
          token.endsWith('.') &&
          (RegExp(r'^[A-ZÇĞİÖŞÜ]{1,2}$').hasMatch(bare) ||
              RegExp(r'^(I|II|III|IV|V|VI|VII|VIII|IX|X)$').hasMatch(bare));
      if (!isAbbrev) {
        sentences.add(current.join(' '));
        current = <String>[];
      }
    }
  }
  if (current.isNotEmpty) sentences.add(current.join(' '));
  final parts = <String>[];
  for (final sentence in sentences) {
    if (sentence.length <= 105) {
      parts.add(sentence);
      continue;
    }
    // Uzun cümleyi virgül/noktalı virgül/iki noktadan, yaklaşık eşit parçalara böl
    final pieces = sentence.split(RegExp(r'(?<=[,;:])\s+'));
    var cur = '';
    for (final piece in pieces) {
      if (cur.isNotEmpty && (cur.length + piece.length) > 105) {
        parts.add(cur);
        cur = piece;
      } else {
        cur = cur.isEmpty ? piece : '$cur $piece';
      }
    }
    if (cur.isNotEmpty) parts.add(cur);
  }
  double weight(String t) {
    var w = t.length.toDouble();
    if (RegExp(r'[.!?…]$').hasMatch(t)) w += 14; // cümle sonunda nefes payı
    if (RegExp(r'[,;:]$').hasMatch(t)) w += 5;
    return w;
  }

  final total = parts.fold<double>(0, (a, b) => a + weight(b));
  final lead = totalSec > 6 ? 0.6 : 0.2;
  final tail = totalSec > 6 ? 0.5 : 0.2;
  final span = (totalSec - lead - tail).clamp(1.0, double.infinity);
  final cues = <SubtitleCue>[];
  var acc = 0.0;
  for (final t in parts) {
    cues.add(SubtitleCue(lead + span * acc / total, t));
    acc += weight(t);
  }
  return cues;
}

/// Videonun altına, oynatma konumuna göre değişen altyazı çizer.
/// [script] boşsa hiçbir şey göstermez.
class VideoSubtitles extends StatelessWidget {
  final VideoPlayerController controller;
  final String script;
  const VideoSubtitles({
    super.key,
    required this.controller,
    required this.script,
  });

  @override
  Widget build(BuildContext context) {
    if (script.trim().isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: SubtitlePrefs.instance,
      builder: (context, _) {
        if (!SubtitlePrefs.instance.on) return const SizedBox.shrink();
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, v, _) {
            if (!v.isInitialized) return const SizedBox.shrink();
            final total = v.duration.inMilliseconds / 1000.0;
            final cues = buildSubtitleCues(script, total);
            if (cues.isEmpty) return const SizedBox.shrink();
            final pos = v.position.inMilliseconds / 1000.0;
            String? text;
            for (final c in cues) {
              if (pos >= c.start) text = c.text;
            }
            if (pos < cues.first.start) text = null;
            return IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: text == null
                    ? const SizedBox(key: ValueKey('none'), height: 0)
                    : Container(
                        key: ValueKey(text),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Altyazıyı açıp kapatan küçük "CC" düğmesi.
class SubtitleToggle extends StatelessWidget {
  const SubtitleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    SubtitlePrefs.instance.load();
    return ListenableBuilder(
      listenable: SubtitlePrefs.instance,
      builder: (context, _) {
        final on = SubtitlePrefs.instance.on;
        return Semantics(
          button: true,
          toggled: on,
          label: context.t('subtitles'),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: SubtitlePrefs.instance.toggle,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: on ? 0.55 : 0.4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: on ? 0.9 : 0.4),
                  width: 1.2,
                ),
              ),
              child: Icon(
                on
                    ? Icons.closed_caption_rounded
                    : Icons.closed_caption_disabled_rounded,
                color: Colors.white.withValues(alpha: on ? 1 : 0.7),
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }
}
