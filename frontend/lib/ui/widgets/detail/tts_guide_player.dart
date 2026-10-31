import 'package:flutter/material.dart';
import 'guide_card.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';

/// Sesli rehber dosyası olmayan eserlerde sayfayı cihazın konuşma motoruyla okur
/// (erişilebilirlik: görme engelliler ve dinlemeyi tercih edenler için).
class TtsGuidePlayer extends StatefulWidget {
  final String text;
  final bool english;

  const TtsGuidePlayer({super.key, required this.text, required this.english});

  @override
  State<TtsGuidePlayer> createState() => _TtsGuidePlayerState();
}

class _TtsGuidePlayerState extends State<TtsGuidePlayer> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  bool _failed = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _tts.setStartHandler(() => _set(() => _speaking = true));
    _tts.setCompletionHandler(
      () => _set(() {
        _speaking = false;
        _progress = 0;
      }),
    );
    _tts.setCancelHandler(() => _set(() => _speaking = false));
    _tts.setPauseHandler(() => _set(() => _speaking = false));
    _tts.setErrorHandler(
      (_) => _set(() {
        _speaking = false;
        _failed = true;
      }),
    );
    _tts.setProgressHandler((text, start, end, word) {
      if (text.isNotEmpty)
        _set(() => _progress = (end / text.length).clamp(0.0, 1.0));
    });
  }

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await _tts.stop();
      _set(() => _speaking = false);
      return;
    }
    try {
      await _tts.setLanguage(widget.english ? 'en-US' : 'tr-TR');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(widget.text);
    } catch (_) {
      _set(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.t('audio_guide'),
      child: GuideCard(
        playing: _speaking,
        onTap: _failed ? null : _toggle,
        title: context.t('audio_guide'),
        bottom: _speaking
            ? Waveform(progress: _progress)
            : Text(
                _failed ? context.t('tts_unavailable') : context.t('tts_hint'),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}
