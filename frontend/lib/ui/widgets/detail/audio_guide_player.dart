import 'package:flutter/material.dart';
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
    final player = AudioPlayer();
    _player = player;
    try {
      final d = await player.setUrl(widget.url);
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    } catch (_) {
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
    return Opacity(
      opacity: _available ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            StreamBuilder<PlayerState>(
              stream: player?.playerStateStream,
              builder: (_, snap) {
                final playing = snap.data?.playing ?? false;
                return GestureDetector(
                  onTap: !_available || player == null
                      ? null
                      : () => playing ? player.pause() : player.play(),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.ciniBordeaux,
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('audio_guide'),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (_available && player != null)
                    StreamBuilder<Duration>(
                      stream: player.positionStream,
                      builder: (_, snap) {
                        final pos = snap.data ?? Duration.zero;
                        final total = _duration.inMilliseconds;
                        final value =
                            total == 0 ? 0.0 : (pos.inMilliseconds / total).clamp(0.0, 1.0);
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 3,
                        );
                      },
                    )
                  else
                    Text(
                      context.t('coming_soon_short'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),
            if (_available) ...[
              const SizedBox(width: 12),
              Text(_fmt(_duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}
