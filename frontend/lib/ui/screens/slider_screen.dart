import '../widgets/common/app_card.dart';
import '../widgets/common/app_icon.dart';
import 'main_screen.dart' show mainTabRequest, mapFocusRequest;
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../widgets/common/action_card.dart';
import '../widgets/common/sheet_handle.dart';
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
import '../widgets/common/feedback_sheet.dart';
import '../widgets/slider/model_3d_view.dart';
import '../widgets/slider/slider_parts.dart';
import 'reels_screen.dart';
import '../widgets/detail/video_dialog.dart';
import '../widgets/slider/split_slider_widget.dart';

/// Eser detayı: Dönem/Bugün karşılaştırma slider'ı, hotspot'lar ve alttan açılan bilgi sayfası.
class SliderScreen extends StatefulWidget {
  final HeritagePlace place;

  /// Eser doğrudan 3B görünümde açılsın (3B modeli varsa).
  final bool start3d;

  /// Açılınca kart yukarı çıkıp "Keşif görevleri" bölümüne kayar (ana ekrandaki mühür kartından).
  final bool focusTasks;

  const SliderScreen({
    super.key,
    required this.place,
    this.start3d = false,
    this.focusTasks = false,
  });

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
  late bool _view3d = widget.start3d && widget.place.has3dModel;
  final TourController _tour = TourController();

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
    if (widget.focusTasks) _scheduleTaskFocus();
    _extentAnim.addListener(() {
      final t = _extentTween;
      if (t != null && mounted) {
        setState(() => _extent = t.evaluate(_extentAnim));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitPhotoArea());
  }

  @override
  void dispose() {
    _sheetScroll.dispose();
    _tasksPulse.dispose();
    _extentAnim.dispose();
    _tour.dispose();
    super.dispose();
  }

  void _expandSheet() => _animateExtentTo(_sheetMax);

  final GlobalKey _tasksKey = GlobalKey();
  final ScrollController _sheetScroll = ScrollController();
  final ValueNotifier<int> _tasksPulse = ValueNotifier<int>(0);

  /// Sayfa açılınca: kart tam yüksekliğe çıkar, görevler bölümüne kayar, başlık vurgulanır.
  void _scheduleTaskFocus() {
    Future<void>.delayed(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      _expandSheet();
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      final ctx = _tasksKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
          alignment: 0.04,
        );
      }
      if (mounted) _tasksPulse.value++;
    });
  }

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
      backgroundColor: canvasOf(context),
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
                  // Modeller koyu modda da özgün renginde kalır (fotoğraflar gibi)
                  DarkCancel(
                    child: Model3DView(
                      darkBackground: DarkScope.invertedOf(context),
                      newUrl: _place.modelNewUrl,
                      oldUrl: _place.modelOldUrl,
                      name: _place.nameFor(en),
                      hotspots: _place.modelHotspots,
                      selected: _selectedHotspot,
                      tourController: _tour,
                      onHotspot: _selectHotspot,
                      bottomInset: _underlap,
                    ),
                  )
                else
                  SplitSliderWidget(
                    topOffset: _place.has3dModel ? 46 : 0,
                    tourController: _tour,
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
                    onHotspotSelected: _selectHotspot,
                  ),
                if (_place.has3dModel)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
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
                color: canvasOf(context),
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
                          controller: _sheetScroll,
                          // Görevler bölümüne kaydırabilmek için alt kısımlar da önceden kurulur
                          cacheExtent: 4000,
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            110 + MediaQuery.of(context).padding.bottom,
                          ),
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
        child: SheetHandle(extraTop: topSafe),
      ),
    );
  }

  /// Sol üstte geri düğmesi: fotoğraf üstündeyken buzlu cam, kart tam ekranken beyaz yuvarlak düğme.
  Widget _viewToggle() {
    Widget seg(IconData icon, String label, bool on, VoidCallback tap) =>
        Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: tap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: on ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: on ? const Color(0xFF1B3A4B) : Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: on ? const Color(0xFF1B3A4B) : Colors.white,
                    ),
                  ),
                ],
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
          seg(
            Icons.photo_library_outlined,
            context.t('view_2d'),
            !_view3d,
            () => setState(() {
              _view3d = false;
              _selectedHotspot = null;
            }),
          ),
          seg(Icons.view_in_ar_rounded, context.t('view_3d'), _view3d, () {
            setState(() {
              _view3d = true;
              _selectedHotspot = null;
            });
          }),
        ],
      ),
    );
  }

  /// Bilgi kartındaki tur kartı: sesli rehberle aynı yumuşak tasarım, durak çubuklarıyla ilerler.
  Widget _tourCard() {
    return ListenableBuilder(
      listenable: _tour,
      builder: (context, _) {
        if (!_tour.available) return const SizedBox.shrink();
        final on = _tour.touring;
        final n = _tour.stops;
        void toggle() {
          // Turun görünmesi için kart aşağı iner
          if (!on && _sheetRaised) _animateExtentTo(_sheetMin);
          _tour.toggle();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Semantics(
            button: true,
            label: on ? context.t('tour_stop') : context.t('tour_start'),
            excludeSemantics: true,
            child: ActionCard(
              leading: ActionCard.iconBubble(
                context,
                on ? Icons.stop_rounded : Icons.play_arrow_rounded,
                filled: true,
              ),
              title: on ? context.t('tour_stop') : context.t('tour_start'),
              subtitle: on ? null : '$n ${context.t('tour_stops')}',
              // Hangi durakta olunduğunu gösteren segmentli çubuk
              bottom: Row(
                children: [
                  for (var i = 0; i < n; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 5,
                        margin: EdgeInsets.only(right: i == n - 1 ? 0 : 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: bordeauxOf(context).withValues(
                            alpha: on && i <= _tour.step ? 0.9 : 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onTap: toggle,
              round: 28,
              shadow: true,
              trailing: on
                  ? Text(
                      '${_tour.step + 1}/$n',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: bordeauxOf(context),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
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
      if (_parent != null) ...[const SizedBox(height: 8), _buildParentLink(en)],
      const SizedBox(height: 16),

      // Dönem / Mimar / Bani
      if (meta.isNotEmpty)
        Wrap(
          spacing: 32,
          runSpacing: 12,
          children: [for (final m in meta) _metaItem(m.key, m.value)],
        ),
      const SizedBox(height: 14),

      // Eseri uygulamanın haritasında göster
      _buildShowOnMap(),
      const SizedBox(height: 18),

      // Tarihî tur (en az iki hotspot varsa)
      _tourCard(),

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
      if (_children.isNotEmpty) ...[
        _buildChildren(en),
        const SizedBox(height: 24),
      ],

      // AI videosu (yatay 16:9); video henüz yoksa "yakında" durumu gösterilir
      _buildVideoCard(videoUrl),
      const SizedBox(height: 16),

      // Sesli rehber
      // Kayıtlı ses varsa onu çalar; yoksa sayfayı cihazın sesiyle okur
      // İngilizce kayıtlı ses yoksa ama İngilizce metin varsa metni cihazın İngilizce sesiyle okuruz;
      // aksi hâlde Türkçe kayıt ile Türkçe metin birlikte gösterilir (ses ile metin hep aynı dilde kalır).
      if (en && _place.audioGuideEnUrl.isEmpty && _place.audioTextEn.isNotEmpty)
        GuideSection(
          player: TtsGuidePlayer(
            key: const ValueKey('tts-audio-en'),
            english: true,
            text: _place.audioTranscript(true).join(' '),
          ),
          transcript: _place.audioTranscript(true),
        )
      else if (audioUrl.isNotEmpty && _place.hasAudioTranscript)
        GuideSection(
          player: AudioGuidePlayer(key: ValueKey(audioUrl), url: audioUrl),
          transcript: _place.audioTranscript(
            en && _place.audioGuideEnUrl.isNotEmpty,
          ),
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
      ActivitiesSection(key: _tasksKey, place: _place, pulse: _tasksPulse),

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
      const SizedBox(height: 8),

      // Bu eserle ilgili geri bildirim
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => FeedbackSheet.show(
            context,
            placeId: _place.id,
            placeName: _place.nameFor(en),
          ),
          icon: const Icon(Icons.rate_review_outlined, size: 18),
          label: Text(context.t('fb_place_link')),
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryTeal),
        ),
      ),
    ];
  }

  /// "Haritada gör": harita sekmesinde bu eseri seçili gösterir (yol tarifi Google Haritalar'a gider).
  Widget _buildShowOnMap() {
    void go() {
      Navigator.of(context).popUntil((r) => r.isFirst);
      mapFocusRequest.value = _place;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: context.t('show_on_map'),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: go,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
            decoration: BoxDecoration(
              color: AppColors.ciniBordeauxLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: bordeauxOf(context).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 17, color: bordeauxOf(context)),
                const SizedBox(width: 7),
                Text(
                  context.t('show_on_map'),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: bordeauxOf(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Alt eserde: "… yapısının bir parçası" bağlantısı.
  /// Başlığın altında küçük bir etiket: dokununca bağlı olduğu yapıya (külliyeye) gider.
  Widget _buildParentLink(bool en) {
    final parent = _parent!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: context.t('part_of').replaceAll('{name}', parent.nameFor(en)),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => _openPlace(parent),
          child: Container(
            padding: const EdgeInsets.fromLTRB(9, 5, 6, 5),
            decoration: BoxDecoration(
              color: AppColors.primaryTealLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryTeal.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  size: 14,
                  color: AppColors.primaryTeal,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    parent.nameFor(en),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTealDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.primaryTeal,
                ),
              ],
            ),
          ),
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
    // Diğer kartlarla aynı köşe şekli
    final shape = appCardBorder(
      round: 40,
      side: bordeauxOf(context, alpha: 0.45),
      width: 1.2,
    );
    return Semantics(
      button: available,
      label: available ? context.t('transform_video') : context.t('video_soon'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: !available
            ? null
            : (videoUrl.isNotEmpty
                  ? () => showVideoDialog(
                      context,
                      videoUrl,
                      script: _place.videoScriptFor(context.isEn),
                    )
                  : () => _openReels(null)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: ShapeDecoration(shape: shape),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: DarkCancel(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video varsa kapak, videonun kendi karesidir; yüklenemezse eser fotoğrafı
                    Image.network(
                      (videoUrl.isNotEmpty ? videoPoster(videoUrl) : null) ??
                          _place.imageAfterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.network(
                        _place.imageAfterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: AppColors.heroPetrol),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.3, 1.0],
                          colors: [Color(0x33000000), Color(0xCC0F2F3A)],
                        ),
                      ),
                    ),
                    const Positioned(top: 14, left: 18, child: AiLabel()),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: available ? 0.95 : 0.8,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primaryTeal.withValues(
                            alpha: available ? 1 : 0.55,
                          ),
                          size: 38,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 14,
                      child: Text(
                        available
                            ? context.t('transform_video')
                            : context.t('video_soon'),
                        style: const TextStyle(
                          fontFamily: AppTheme.headingFont,
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

  void _openInventory() => LauncherUtil.openUrl(
    AppLinks.inventoryBooks,
    source: 'place_card',
    placeId: _place.id,
  );

  void _selectHotspot(Hotspot? h) {
    setState(() => _selectedHotspot = h);
  }

  Widget _buildSourceCard(bool en) {
    final inventory = _inventoryLabel(en);
    return Semantics(
      button: true,
      label:
          '${context.t('source_book')}. ${inventory.isNotEmpty ? inventory : context.t('source_label')}',
      hint: context.t('source_open'),
      excludeSemantics: true,
      onTap: _openInventory,
      child: GestureDetector(
        onTap: _openInventory,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: appCardDecoration(
            round: 28,
            shadow: false,
            side: bordeauxOf(context, alpha: 0.4),
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
                foregroundColor: bordeauxOf(context),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: bordeauxOf(context).withValues(alpha: 0.5),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
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
                final accent = bordeauxOf(context);
                return OutlinedButton.icon(
                  onPressed: _toggleRoute,
                  icon: inRoute
                      ? const Icon(Icons.check_rounded, size: 22)
                      : AppIcon('add', size: 24, color: accent),
                  label: Text(
                    inRoute ? context.t('in_route') : context.t('add_to_route'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: inRoute ? Colors.white : accent,
                    backgroundColor: inRoute
                        ? accent
                        : AppColors.ciniBordeauxLight,
                    side: BorderSide(
                      color: accent.withValues(alpha: inRoute ? 1 : 0.5),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
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
                  foregroundColor: Colors.white,
                  side: BorderSide.none,
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
                  foregroundColor: Colors.white,
                  side: BorderSide.none,
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
