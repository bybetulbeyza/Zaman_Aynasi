import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/common/ai_label.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/dark_cancel.dart';
import '../widgets/common/logo_loader.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import 'slider_screen.dart';
import '../widgets/detail/video_subtitles.dart';

class _Reel {
  final HeritagePlace place;
  final Hotspot hotspot;
  final String url;
  const _Reel(this.place, this.hotspot, this.url);
}

/// Hotspot AI videolarını dikey, kaydırılabilir akışta (Reels) gösterir.
/// [initialPlace] verilirse akış o eserin videosundan başlar.
class ReelsScreen extends StatefulWidget {
  final HeritagePlace? initialPlace;

  /// true ise akış yalnızca [initialPlace] eserinin hotspot videolarını içerir.
  final bool placeOnly;

  /// Verilirse akış bu hotspot'un videosundan başlar.
  final dynamic initialHotspotId;

  const ReelsScreen({
    super.key,
    this.initialPlace,
    this.placeOnly = false,
    this.initialHotspotId,
  });

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _page = PageController();
  List<_Reel> _reels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final en = AppLang.instance.isEnglish;
    final List<HeritagePlace> places =
        widget.placeOnly && widget.initialPlace != null
        ? [widget.initialPlace!]
        : await HeritageRepository().getPlaces();
    final reels = <_Reel>[];
    for (final p in places) {
      for (final h in p.hotspots) {
        final url = h.videoFor(en);
        if (url != null) reels.add(_Reel(p, h, url));
      }
    }
    var start = -1;
    if (widget.initialHotspotId != null) {
      start = reels.indexWhere((r) => r.hotspot.id == widget.initialHotspotId);
    } else if (widget.initialPlace != null) {
      start = reels.indexWhere((r) => r.place.id == widget.initialPlace!.id);
    }
    if (!mounted) return;
    setState(() {
      _reels = reels;
      _loading = false;
    });
    if (start > 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _page.jumpToPage(start),
      );
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DarkCancel(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_loading)
              const Center(child: LogoLoader(textColor: Colors.white70))
            else if (_reels.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    context.t('reels_empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              )
            else
              PageView.builder(
                controller: _page,
                scrollDirection: Axis.vertical,
                itemCount: _reels.length,
                itemBuilder: (_, i) => _ReelPage(
                  key: ValueKey('${_reels[i].hotspot.id}'),
                  reel: _reels[i],
                  pageController: _page,
                  index: i,
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const AppBackButton(onPhoto: true),
                    Text(
                      context.t('reels_title'),
                      style: const TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelPage extends StatefulWidget {
  final _Reel reel;
  final PageController pageController;
  final int index;
  const _ReelPage({
    super.key,
    required this.reel,
    required this.pageController,
    required this.index,
  });

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _c;
  bool _error = false;
  // "Sağa kaydır" okları: hafifçe sağa kayıp geri döner, sürekli tekrarlar
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.reel.url))
      ..setLooping(true)
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {});
              _syncPlayback();
            }
          })
          .catchError((_) {
            if (mounted) setState(() => _error = true);
          });
    widget.pageController.addListener(_syncPlayback);
  }

  void _openDetails() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SliderScreen(place: widget.reel.place)),
  );

  /// Yalnızca ekranda tam görünen sayfa oynar.
  void _syncPlayback() {
    if (!_c.value.isInitialized) return;
    final page = widget.pageController.positions.length == 1
        ? widget.pageController.page
        : 0.0;
    final visible = ((page ?? 0) - widget.index).abs() < 0.5;
    if (visible && !_c.value.isPlaying) _c.play();
    if (!visible && _c.value.isPlaying) _c.pause();
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_syncPlayback);
    _hint.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = context.isEn;
    final r = widget.reel;
    final script = r.hotspot.videoScriptFor(en);
    final hasScript = script.trim().isNotEmpty;
    return GestureDetector(
      onTap: () => setState(() => _c.value.isPlaying ? _c.pause() : _c.play()),
      // Sağa kaydırınca eser sayfası açılır
      onHorizontalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 280) _openDetails();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_error)
            Center(
              child: Text(
                context.t('video_error'),
                style: const TextStyle(color: Colors.white70),
              ),
            )
          else if (!_c.value.isInitialized)
            const Center(child: LogoLoader(textColor: Colors.white70))
          else
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _c.value.size.width,
                height: _c.value.size.height,
                child: VideoPlayer(_c),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.55, 1.0],
                colors: [Colors.transparent, Color(0xDD000000)],
              ),
            ),
          ),
          if (_c.value.isInitialized && !_c.value.isPlaying)
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 76,
                color: Colors.white70,
              ),
            ),
          if (hasScript)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 14,
              child: const SubtitleToggle(),
            ),
          // Reels düzeni: solda küçük AI etiketi, altyazı üstte; sağ altta "Detaylar" düğmesi
          Positioned(
            left: 20,
            right: 20,
            bottom: 34,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasScript)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: VideoSubtitles(controller: _c, script: script),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const AiLabel(compact: true),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: context.t('swipe_details'),
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openDetails,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.38),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  width: 1.3,
                                ),
                              ),
                              // Sağa kayıp geri dönen çift ok
                              child: AnimatedBuilder(
                                animation: _hint,
                                builder: (context, child) {
                                  final t = Curves.easeInOut.transform(
                                    _hint.value,
                                  );
                                  return Transform.translate(
                                    offset: Offset(-3 + 6 * t, 0),
                                    child: Opacity(
                                      opacity: 0.65 + 0.35 * t,
                                      child: child,
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.keyboard_double_arrow_right_rounded,
                                  size: 26,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              context.t('details_short'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
