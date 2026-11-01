import '../widgets/common/app_icon.dart';
import 'main_screen.dart' show mainTabRequest;
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../widgets/common/ai_label.dart';
import '../widgets/common/dark_cancel.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/squircle_frame.dart';
import '../widgets/common/app_toast.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/state/active_route.dart';
import '../../core/utils/launcher_util.dart';
import '../../data/models/heritage_place.dart';
import '../../core/constants/category_style.dart';
import '../../data/repositories/heritage_repository.dart';
import '../widgets/common/app_network_image.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/lang_toggle.dart';
import '../widgets/common/section_title.dart';
import '../widgets/detail/audio_guide_player.dart';
import '../widgets/detail/tts_guide_player.dart';
import '../widgets/detail/photo_collage.dart';
import '../widgets/detail/activities_section.dart';
import '../widgets/detail/guide_section.dart';
import '../widgets/detail/swipe_hint_arrow.dart';
import '../widgets/slider/model_3d_view.dart';
import 'reels_screen.dart';
import '../widgets/detail/video_dialog.dart';
import '../widgets/slider/split_slider_widget.dart';

/// Eser detayı: Dönem/Bugün karşılaştırma slider'ı, hotspot'lar ve alttan açılan bilgi sayfası.
class SliderScreen extends StatefulWidget {
  final HeritagePlace place;

  const SliderScreen({super.key, required this.place});

  @override
  State<SliderScreen> createState() => _SliderScreenState();
}

class _SliderScreenState extends State<SliderScreen>
    with SingleTickerProviderStateMixin {
  // Kart, yalnızca bordo tutamaçtan sürüklenince büyür; içeriği kaydırmak kartı oynatmaz.
  // En fazla tam ekran olur.
  static const double _sheetMax = 1.0;
  double _extent =
      0.54; // kartın ekran yüksekliğine oranı (başlangıçta _sheetMin)
  bool get _sheetRaised => _extent > _sheetMin + 0.04;

  late final AnimationController _extentAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  Animatable<double>? _extentTween;

  void _animateExtentTo(double to) {
    _extentAnim.stop();
    _extentTween = Tween<double>(
      begin: _extent,
      end: to,
    ).chain(CurveTween(curve: Curves.easeOutCubic));
    _extentAnim.forward(from: 0);
  }

  static const double _underlap =
      28; // fotoğraf, sayfanın yuvarlak köşelerinin altına uzanır

  /// Fotoğraf alanının ekran yüksekliğine oranı: fotoğraf oranına göre hesaplanır,
  /// böylece büyük görünür ama gereksiz kırpılmaz.
  double _photoFraction = 0.46;
  double get _sheetMin => 1 - _photoFraction;

  Future<void> _fitPhotoArea() async {
    final aspects = <double>[];
    for (final url in [_place.imageBeforeUrl, _place.imageAfterUrl]) {
      if (url.isEmpty) continue;
      final a = await _loadAspect(url);
      if (a != null) aspects.add(a);
    }
    if (aspects.isEmpty || !mounted) return;
    final avg = aspects.reduce((a, b) => a + b) / aspects.length;
    final size = MediaQuery.of(context).size;
    final fraction = ((size.width / avg) * 1.15 / size.height).clamp(
      0.40,
      0.52,
    );
    if ((fraction - _photoFraction).abs() < 0.005) return;
    final wasMin = !_sheetRaised;
    setState(() {
      _photoFraction = fraction;
      if (wasMin) _extent = _sheetMin;
    });
  }

  Future<double?> _loadAspect(String url) {
    final completer = Completer<double?>();
    final stream = CachedNetworkImageProvider(
      url,
    ).resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(info.image.width / info.image.height);
      },
      onError: (_, __) {
        stream.removeListener(listener);
        completer.complete(null);
      },
    );
    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  }

  Hotspot? _selectedHotspot;
  bool _showHint = false;
  bool _view3d = false;
  Timer? _hintTimer;

  HeritagePlace get _place => widget.place;

  /// Külliye gibi üst yapıysa alt eserleri; alt eserse bağlı olduğu üst yapıyı gösterir.
  List<HeritagePlace> _children = [];
  HeritagePlace? _parent;

  Future<void> _loadRelated() async {
    final all = await HeritageRepository().getPlacesCached();
    if (!mounted || all.isEmpty) return;
    setState(() {
      _children = all.where((p) => p.parentId == _place.id).toList();
      _parent = _place.parentId == null
          ? null
          : all.where((p) => p.id == _place.parentId).firstOrNull;
    });
  }

  void _openPlace(HeritagePlace place) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SliderScreen(place: place)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRelated();
    _extentAnim.addListener(() {
      final t = _extentTween;
      if (t != null && mounted) {
        setState(() => _extent = t.evaluate(_extentAnim));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitPhotoArea());
    // Hotspot'ların varlığını ilk bakışta anlatan kısa ipucu
    if (_place.hotspots.isNotEmpty) {
      _showHint = true;
      _hintTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() => _showHint = false);
      });
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _extentAnim.dispose();
    super.dispose();
  }

  void _expandSheet() => _animateExtentTo(_sheetMax);

  bool get _hasHotspotVideos =>
      _place.hotspots.any((h) => h.videoFor(context.isEn) != null);

  /// Eserin hotspot videolarını dikey kaydırmalı akışta açar (verilirse o hotspot'tan başlar).
  void _openReels(Hotspot? start) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReelsScreen(
          initialPlace: _place,
          placeOnly: true,
          initialHotspotId: start?.id,
        ),
      ),
    );
  }

  /// Sesli okuma için sayfa metni: ad, kısa tarihçe ve hotspot açıklamaları.
  String _pageText(bool en) {
    final b = StringBuffer()
      ..writeln('${_place.nameFor(en)}.')
      ..writeln('${_place.descriptionFor(en)}');
    for (final h in _place.hotspots) {
      b
        ..writeln('${h.titleFor(en)}.')
        ..writeln(h.descriptionFor(en));
    }
    return b.toString();
  }

  /// "Cilt 1, s. 37" -> İngilizcede "Vol. 1, p. 37"
  String _inventoryLabel(bool en) {
    final raw = _place.inventoryLocation;
    if (!en) return raw;
    return raw.replaceAll('Cilt', 'Vol.').replaceAll(RegExp(r's\.\s*'), 'p. ');
  }

  void _toggleRoute() {
    final route = ActiveRoute.instance;
    if (route.contains(_place)) {
      route.remove(_place);
      _toast(context.t('route_removed'), Icons.remove_circle_outline_rounded);
    } else {
      route.add(_place);
      _toast(
        context.t('route_added').replaceAll('{n}', '${route.length}'),
        Icons.check_rounded,
        action: context.t('route_view'),
      );
    }
  }

  /// Alt eylem çubuğunun üstünde yüzen bildirim; [action] verilirse rotalar sekmesine götürür.
  void _toast(String text, IconData icon, {String? action}) {
    AppToast.show(
      context,
      text,
      icon: icon,
      actionLabel: action,
      bottomMargin: 92,
      onAction: () {
        Navigator.of(context).popUntil((r) => r.isFirst);
        mainTabRequest.value = 3;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final en = context.isEn;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Stack(
        children: [
          // 1. Dönem / Bugün karşılaştırma alanı
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * _photoFraction + _underlap,
            child: Stack(
              children: [
                if (_view3d)
                  Model3DView(
                    newUrl: _place.modelNewUrl,
                    oldUrl: _place.modelOldUrl,
                    name: _place.nameFor(en),
                    hotspots: _place.modelHotspots,
                    onHotspot: (h) => setState(() => _selectedHotspot = h),
                    bottomInset: _underlap,
                  )
                else
                  SplitSliderWidget(
                    beforeImageUrl: _place.imageBeforeUrl,
                    afterImageUrl: _place.imageAfterUrl,
                    afterLabel: context.t('period_label'),
                    beforeLabel: context.t('today_label'),
                    hotspots: _place.hotspots,
                    selectedHotspot: _selectedHotspot,
                    navCategories: {
                      for (final c in _children) c.id: c.category,
                    },
                    bottomInset: _underlap,
                    onHotspotSelected: (h) => setState(() {
                      _selectedHotspot = h;
                      _showHint = false;
                    }),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: size.height * _photoFraction - size.height * 0.1,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: _showHint && _selectedHotspot == null ? 1 : 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.touch_app_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.t('hotspot_hint'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_place.has3dModel)
                  Positioned(
                    top:
                        MediaQuery.of(context).padding.top +
                        (_view3d ? 12 : 64),
                    right: 14,
                    child: _viewToggle(),
                  ),
                if (_selectedHotspot != null)
                  Positioned(
                    top: size.height * 0.11,
                    left: 20,
                    right: 20,
                    child: _buildHotspotPopup(_selectedHotspot!, en),
                  ),
              ],
            ),
          ),

          // 2. Alt bilgi kartı: yalnızca tutamaçtan sürüklenir, içerik kendi içinde kayar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * _extent,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCanvas,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: PatternBackground(
                  lineOpacity: 0.07,
                  child: Column(
                    children: [
                      _buildDragHandle(size),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                          children: _buildSheetContent(en),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Geri oku: kart tam ekran olunca da görünsün diye kartın üstünde durur
          _buildBackArrow(),

          // 3. Sabit alt eylem çubuğu
          Positioned(left: 0, right: 0, bottom: 0, child: _buildActionBar()),
        ],
      ),
    );
  }

  /// Bordo tutamaç: yukarı çekince kart tam ekran olur, aşağı çekince fotoğraf geri gelir.
  Widget _buildDragHandle(Size size) {
    final progress = ((_extent - _sheetMin) / (_sheetMax - _sheetMin)).clamp(
      0.0,
      1.0,
    );
    final topSafe = MediaQuery.of(context).padding.top * progress;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _animateExtentTo(_sheetRaised ? _sheetMin : _sheetMax),
      onVerticalDragUpdate: (d) {
        _extentAnim.stop();
        setState(() {
          _extent = (_extent - d.delta.dy / size.height).clamp(
            _sheetMin,
            _sheetMax,
          );
        });
      },
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        final mid = (_sheetMin + _sheetMax) / 2;
        final to = v < -300
            ? _sheetMax
            : v > 300
            ? _sheetMin
            : (_extent > mid ? _sheetMax : _sheetMin);
        _animateExtentTo(to);
      },
      child: Semantics(
        button: true,
        label: _sheetRaised
            ? context.t('a11y_sheet_down')
            : context.t('a11y_sheet_up'),
        excludeSemantics: true,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(0, 12 + topSafe, 0, 16),
          alignment: Alignment.topCenter,
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCFC5B3), // sıcak, kremsi gri-bej
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  /// Sol üstte geri düğmesi: fotoğraf üstündeyken buzlu cam, kart tam ekranken beyaz yuvarlak düğme.
  Widget _viewToggle() {
    Widget seg(String label, bool on, VoidCallback tap) => Semantics(
      button: true,
      selected: on,
      label: label,
      child: GestureDetector(
        onTap: tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: on ? const Color(0xFF1B3A4B) : Colors.white,
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(context.t('view_2d'), !_view3d, () {
            setState(() {
              _view3d = false;
              _selectedHotspot = null;
            });
          }),
          seg(context.t('view_3d'), _view3d, () {
            setState(() {
              _view3d = true;
              _selectedHotspot = null;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildBackArrow() {
    final onSheet = _extent > 0.9;
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: AppBackButton(onPhoto: !onSheet),
        ),
      ),
    );
  }

  List<Widget> _buildSheetContent(bool en) {
    final videoUrl = _place.videoFor(en);
    final audioUrl = _place.audioFor(en);
    final meta = <MapEntry<String, String>>[
      if (_place.constructionDate.isNotEmpty)
        MapEntry(context.t('period'), _place.constructionDate),
      if (_place.architect.isNotEmpty)
        MapEntry(context.t('architect'), _place.architect),
      if (_place.patron.isNotEmpty)
        MapEntry(context.t('patron'), _place.patron),
    ];

    return [
      // Başlık + dil
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              _place.nameFor(en),
              style: AppTheme.displayLarge.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(width: 12),
          const LangToggle(),
        ],
      ),
      const SizedBox(height: 16),

      // Dönem / Mimar / Bani
      if (meta.isNotEmpty)
        Wrap(
          spacing: 32,
          runSpacing: 12,
          children: [for (final m in meta) _metaItem(m.key, m.value)],
        ),
      const SizedBox(height: 18),

      // Kartın yukarı çekilebildiğini gösteren zıplayan ok (kart açılınca solar)
      AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _sheetRaised ? 0 : 1,
        child: IgnorePointer(
          ignoring: _sheetRaised,
          child: SwipeHintArrow(onTap: _expandSheet),
        ),
      ),

      // Külliye ise alt yapıları, alt eser ise bağlı olduğu yapı
      if (_parent != null) ...[
        _buildParentLink(en),
        const SizedBox(height: 18),
      ],
      if (_children.isNotEmpty) ...[
        _buildChildren(en),
        const SizedBox(height: 24),
      ],

      // AI videosu
      _buildVideoCard(videoUrl),
      const SizedBox(height: 16),

      // Sesli rehber
      // Kayıtlı ses varsa onu çalar; yoksa sayfayı cihazın sesiyle okur
      if (audioUrl.isNotEmpty && _place.hasAudioTranscript)
        GuideSection(
          player: AudioGuidePlayer(key: ValueKey(audioUrl), url: audioUrl),
          transcript: _place.audioTranscript(en),
        )
      else if (audioUrl.isNotEmpty)
        AudioGuidePlayer(key: ValueKey(audioUrl), url: audioUrl)
      else
        TtsGuidePlayer(
          key: ValueKey('tts-$en'),
          english: en,
          text: _pageText(en),
        ),
      const SizedBox(height: 26),

      // Tarihçe
      SectionTitle(context.t('history')),
      const SizedBox(height: 10),
      Text(
        _place.descriptionFor(en),
        style: const TextStyle(
          fontSize: 16,
          height: 1.55,
          color: AppColors.textDark,
        ),
      ),
      const SizedBox(height: 26),

      // Keşif görevleri (görev yoksa görünmez)
      ActivitiesSection(place: _place),

      // Eski fotoğraf envanteri (fotoğraf yoksa hiç görünmez)
      if (_place.oldPhotos.isNotEmpty) ...[
        SectionTitle(context.t('old_photos')),
        const SizedBox(height: 12),
        PhotoCollage(
          photos: _place.oldPhotos,
          semanticPrefix: _place.nameFor(en),
        ),
        const SizedBox(height: 26),
      ],

      // Kaynakça
      SectionTitle(context.t('sources')),
      const SizedBox(height: 12),
      _buildSourceCard(en),
      const SizedBox(height: 12),
      _buildAiNote(),
    ];
  }

  /// Alt eserde: "… yapısının bir parçası" bağlantısı.
  Widget _buildParentLink(bool en) {
    final parent = _parent!;
    return GestureDetector(
      onTap: () => _openPlace(parent),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryTealLight,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.account_tree_outlined,
              size: 20,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.t('part_of').replaceAll('{name}', parent.nameFor(en)),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTealDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryTeal,
            ),
          ],
        ),
      ),
    );
  }

  /// Külliyede: alt yapıların fotoğraflı, yatay kaydırmalı listesi.
  Widget _buildChildren(bool en) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(context.t('complex_parts')),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = _children[i];
              final style = CategoryStyle.of(c.category);
              return GestureDetector(
                onTap: () => _openPlace(c),
                child: SizedBox(
                  width: 132,
                  child: SquircleFrame(
                    radius: 30,
                    elevated: false,
                    child: DarkCancel(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppNetworkImage(
                            imageUrl: c.imageAfterUrl,
                            semanticLabel: c.nameFor(en),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.4, 1.0],
                                colors: [Colors.transparent, Color(0xCC0F2F3A)],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: style.color,
                                shape: BoxShape.circle,
                              ),
                              child: AppIcon(
                                style.icon,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Text(
                              c.nameFor(en),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTheme.headingFont,
                                fontSize: 15,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _metaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(String videoUrl) {
    final available = videoUrl.isNotEmpty || _hasHotspotVideos;
    const radius = BorderRadius.all(Radius.circular(20));
    return GestureDetector(
      onTap: !available
          ? null
          : (videoUrl.isNotEmpty
                ? () => showVideoDialog(context, videoUrl)
                : () => _openReels(null)),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: bordeauxOf(context, alpha: 0.45),
            width: 1.1,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: DarkCancel(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _place.imageAfterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: AppColors.heroPetrol),
                ),
                Container(color: Colors.black.withValues(alpha: 0.28)),
                Positioned(top: 12, left: 12, child: const AiLabel()),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: available ? 1 : 0.7,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      available
                          ? Icons.play_arrow_rounded
                          : Icons.hourglass_empty_rounded,
                      color: AppColors.primaryTeal,
                      size: 34,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: Text(
                    available
                        ? context.t('transform_video')
                        : context.t('video_soon'),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kaynakça altında, tarihî görselin yapay zekâ canlandırması olduğunu belirten düz not.
  Widget _buildAiNote() {
    return Text(
      context.t('source_ai_note'),
      style: const TextStyle(
        fontSize: 14.5,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryTeal,
      ),
    );
  }

  Widget _buildSourceCard(bool en) {
    final inventory = _inventoryLabel(en);
    return Semantics(
      button: true,
      label:
          '${context.t('source_book')}. ${inventory.isNotEmpty ? inventory : context.t('source_label')}',
      hint: context.t('source_open'),
      excludeSemantics: true,
      onTap: () => LauncherUtil.openUrl(AppLinks.inventoryBooks),
      child: GestureDetector(
        onTap: () => LauncherUtil.openUrl(AppLinks.inventoryBooks),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: bordeauxOf(context, alpha: 0.4),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTealLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 22,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('source_book'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inventory.isNotEmpty
                          ? inventory
                          : context.t('source_label'),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: AppColors.primaryTeal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.dividerLine, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => LauncherUtil.openDirections(_place.location),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                side: const BorderSide(
                  color: AppColors.primaryTeal,
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(context.t('directions')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListenableBuilder(
              listenable: ActiveRoute.instance,
              builder: (context, _) {
                final inRoute = ActiveRoute.instance.contains(_place);
                return ElevatedButton.icon(
                  onPressed: _toggleRoute,
                  icon: inRoute
                      ? const Icon(Icons.check_rounded, size: 22)
                      : const AppIcon('add', size: 24, color: Colors.white),
                  label: Text(
                    inRoute ? context.t('in_route') : context.t('add_to_route'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inRoute
                        ? AppColors.primaryTealDark
                        : AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Hotspot ---

  /// Yönlendirme hotspot'unun gideceği alt eser (yalnızca bu külliyenin alt yapıları arasından).
  HeritagePlace? _navTarget(Hotspot hotspot) {
    if (!hotspot.hasSubPlaceNavigation) return null;
    return _children.where((c) => c.id == hotspot.targetPlaceId).firstOrNull;
  }

  /// Hotspot kartının kabuğu: uygulamanın krem zemini ve çini deseni, diğer kartlarla aynı köşe dili.
  Widget _popupShell({required Widget child}) {
    const border = BorderRadius.only(
      topLeft: Radius.circular(10),
      bottomRight: Radius.circular(10),
      topRight: Radius.circular(34),
      bottomLeft: Radius.circular(34),
    );
    final shape = ContinuousRectangleBorder(
      borderRadius: border,
      side: const BorderSide(color: AppColors.chipBorder, width: 1.2),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: PatternBackground(
          lineOpacity: 0.07,
          child: Padding(padding: const EdgeInsets.all(18), child: child),
        ),
      ),
    );
  }

  Widget _buildHotspotPopup(Hotspot hotspot, bool en) {
    final videoUrl = hotspot.videoFor(en);
    final target = _navTarget(hotspot);
    return _popupShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  hotspot.titleFor(en),
                  style: const TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedHotspot = null),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Semantics(
                    button: true,
                    label: context.t('a11y_close'),
                    excludeSemantics: true,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _shortIntro(hotspot.descriptionFor(en)),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          if (target != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openPlace(target),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.heroPetrol,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text('${context.t('go_to_part')} →'),
              ),
            ),
          ],
          if (videoUrl != null) ...[
            SizedBox(height: target != null ? 10 : 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openReels(hotspot),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(context.t('ai_story')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: bordeauxOf(context),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Açıklamanın "Kaynak: …" kısmını atıp ilk cümle(ler)den kısa bir tanıtım üretir.
  String _shortIntro(String text) {
    var t = text.split(RegExp(r'\s*(Kaynak|Source):')).first.trim();
    final sentences = t.split(RegExp(r'(?<=[.!?])\s+'));
    final out = StringBuffer(sentences.first);
    for (final sentence in sentences.skip(1)) {
      if (out.length + sentence.length > 130) break;
      out.write(' $sentence');
    }
    return out.toString();
  }
}
