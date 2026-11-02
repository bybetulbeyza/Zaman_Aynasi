import 'package:flutter/material.dart';
import '../common/logo_loader.dart';
import '../common/dark_cancel.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';

/// AI videosunu tam ekran bir pencerede oynatır.
Future<void> showVideoDialog(BuildContext context, String url) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => _VideoDialog(url: url),
  );
}

class _VideoDialog extends StatefulWidget {
  final String url;
  const _VideoDialog({required this.url});

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  late final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {});
              _controller.play();
            }
          })
          .catchError((_) {
            if (mounted) setState(() => _hasError = true);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller.value.isInitialized;
    return DarkCancel(
      child: Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_hasError)
                Text(
                  context.t('video_error'),
                  style: const TextStyle(color: Colors.white70),
                )
              else if (!ready)
                const LogoLoader(size: 48)
              else
                GestureDetector(
                  onTap: () => setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  }),
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: AppColors.primaryTeal,
                          ),
                        ),
                        if (!_controller.value.isPlaying)
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 72,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Semantics(
                    button: true,
                    label: context.t('a11y_close'),
                    excludeSemantics: true,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
