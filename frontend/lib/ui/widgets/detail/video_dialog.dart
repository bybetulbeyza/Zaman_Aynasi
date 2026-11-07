import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/logo_loader.dart';
import '../common/dark_cancel.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import 'video_subtitles.dart';

/// AI videosunu tam ekran bir pencerede oynatır.
Future<void> showVideoDialog(
  BuildContext context,
  String url, {
  String script = '',
}) {
  return showDialog<void>(
    context: context,
    barrierColor: scrimOf(context, 0.87),
    builder: (_) => _VideoDialog(url: url, script: script),
  );
}

class _VideoDialog extends StatefulWidget {
  final String url;
  final String script;
  const _VideoDialog({required this.url, this.script = ''});

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  late final VideoPlayerController _controller;
  bool _hasError = false;
  bool _fullscreen = false;

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

  /// Yatay videoyu tam ekran yapar: cihazı yataya çevirir, durum/gezinme çubuklarını gizler.
  Future<void> _setFullscreen(bool on) async {
    setState(() => _fullscreen = on);
    if (on) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await _restoreSystemUi();
    }
  }

  /// Tam ekrandan çıkış: uygulamanın normal yönü olan dikeye döner (main.dart ile aynı kilit).
  static Future<void> _restoreSystemUi() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    // Pencere kapanınca ses hemen kesilsin, ekran yönü eski hâline dönsün
    _controller.pause();
    _controller.dispose();
    if (_fullscreen) _restoreSystemUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller.value.isInitialized;
    final landscape = ready && _controller.value.aspectRatio > 1.05;
    return PopScope(
      // Tam ekrandayken geri tuşu önce tam ekrandan çıkar
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _fullscreen) _setFullscreen(false);
      },
      child: DarkCancel(
        child: Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            // Tam ekranda sistem ekranı yataya çeviremezse (ör. Android 16 tabletler) içerik kendisi döner
            child: _rotateIfPortrait(
              Stack(
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
                  // Altyazı ekranın altında: yatay videoda görüntünün ortasını kapatmaz
                  if (ready)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: _fullscreen ? 14 : 28,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: VideoSubtitles(
                            controller: _controller,
                            script: widget.script,
                          ),
                        ),
                      ),
                    ),
                  if (widget.script.trim().isNotEmpty)
                    const Positioned(
                      top: 14,
                      left: 14,
                      child: SubtitleToggle(),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (landscape)
                          IconButton(
                            tooltip: context.t(
                              _fullscreen ? 'exit_fullscreen' : 'fullscreen',
                            ),
                            icon: Icon(
                              _fullscreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: () => _setFullscreen(!_fullscreen),
                          ),
                        IconButton(
                          icon: Semantics(
                            button: true,
                            label: context.t('a11y_close'),
                            excludeSemantics: true,
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tam ekrandayken alan hâlâ dikeyse içeriği 90° döndürür; yatayda olduğu gibi bırakır.
  Widget _rotateIfPortrait(Widget child) => LayoutBuilder(
    builder: (context, box) {
      final portrait = box.maxHeight > box.maxWidth;
      return (_fullscreen && portrait)
          ? RotatedBox(quarterTurns: 1, child: child)
          : child;
    },
  );
}
