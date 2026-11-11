import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'guide_card.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';

/// Sesli rehber çubuğu. [url] boşsa "yakında" durumunda pasif görünür.
class AudioGuidePlayer extends StatefulWidget {
  final String url;

  const AudioGuidePlayer({super.key, required this.url});

  @override
  State<AudioGuidePlayer> createState() => _AudioGuidePlayerState();
}

class _AudioGuidePlayerState extends State<AudioGuidePlayer> {
  AudioPlayer? _player;
  Duration _duration = Duration.zero;
  bool _hasError = false;

  bool get _available => widget.url.isNotEmpty && !_hasError;

  @override
  void initState() {
    super.initState();
    if (widget.url.isNotEmpty) _init();
  }

  Future<void> _init() async {
    _player?.dispose();
    final player = AudioPlayer();
    _player = player;
    try {
      final d = await player.setUrl(widget.url);
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    } catch (e) {
      debugPrint('Sesli rehber yüklenemedi (${widget.url}): $e');
      if (mounted) setState(() => _hasError = true);
    }
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        player.pause();
        player.seek(Duration.zero);
      }
    });
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    return StreamBuilder<PlayerState>(
      stream: player?.playerStateStream,
      builder: (_, stateSnap) {
        final playing = stateSnap.data?.playing ?? false;
        return GuideCard(
          dimmed: !_available,
          playing: playing,
          title: context.t('audio_guide'),
          trailing: _available ? _fmt(_duration) : null,
          onTap: _hasError
              ? () {
                  setState(() => _hasError = false);
                  _init();
                }
              : (!_available || player == null)
              ? null
              : () => playing ? player.pause() : player.play(),
          bottom: (_available && player != null)
              ? StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (_, snap) {
                    final pos = snap.data ?? Duration.zero;
                    final total = _duration.inMilliseconds;
                    final value = total == 0
                        ? 0.0
                        : (pos.inMilliseconds / total).clamp(0.0, 1.0);
                    return Waveform(
                      progress: value,
                      onSeek: total == 0
                          ? null
                          : (f) => player.seek(
                              Duration(milliseconds: (f * total).round()),
                            ),
                    );
                  },
                )
              : Text(
                  context.t('coming_soon_short'),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
        );
      },
    );
  }
}
