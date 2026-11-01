import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../common/dark_cancel.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_icon.dart';
import 'slider_parts.dart';
import '../common/app_network_image.dart';
import '../../../core/constants/category_style.dart';

class SplitSliderWidget extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final String beforeLabel;
  final String afterLabel;
  final List<Hotspot> hotspots;
  final ValueChanged<Hotspot?>? onHotspotSelected;

  /// Şu an bilgi kartı açık olan hotspot. Kart kapanınca kamera eski haline döner.
  final Hotspot? selectedHotspot;

  /// Yönlendirme hotspot'unun gideceği yapının kategorisi (id -> kategori). Nokta bu renkte ve
  /// bu kategorinin simgesiyle çizilir.
  final Map<String, PlaceCategory> navCategories;

  /// Bu kadar piksel alt kısım bilgi sayfasının altında kalır; butonlar bunun üstüne yerleşir.
  final double bottomInset;

  /// Üstteki sağ düğme sütununa (ör. 2B|3B geçişi) yer açmak için kaydırma.
  final double topOffset;

  /// Turu dışarıdaki (bilgi kartındaki) düğmeden başlatmak için.
  final TourController? tourController;

  const SplitSliderWidget({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.beforeLabel = 'Bugün',
    this.afterLabel = 'Dönem',
    this.hotspots = const [],
    this.onHotspotSelected,
    this.selectedHotspot,
    this.navCategories = const {},
    this.bottomInset = 0,
    this.topOffset = 0,
    this.tourController,
  });

  @override
  State<SplitSliderWidget> createState() => _SplitSliderWidgetState();
}

class _SplitSliderWidgetState extends State<SplitSliderWidget>
    with TickerProviderStateMixin {
  double _sliderValue = 0.5;
  bool _active = false; // kullanıcı slider'ı sürüklerken tutamaç büyür
  Timer? _activeTimer;
  bool _showHotspots = true;
  late AnimationController _pulseController;

  // Fotoğrafların en/boy oranları: hotspot konumları fotoğrafa göre tutulur, kutuya göre değil.
  double? _oldAspect; // sol taraf (image_before_url, 'after' hotspot'ları)
  double? _newAspect; // sağ taraf (image_after_url, 'before' hotspot'ları)

  // Yakınlaştırma: iki parmakla büyüt, çift dokunmayla 2.5x, basılı tutunca "zaman merceği"
  static const double _maxZoom = 4;
  static const double _lensRadius = 72;
  static const double _lensMagnify = 2.4;
  double _zoom = 1;
  Offset _pan = Offset.zero;
  late final AnimationController _zoomAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  double _zFrom = 1, _zTo = 1;
  Offset _pFrom = Offset.zero, _pTo = Offset.zero;
  int _lastPointers = 0;
  double _baseZoom = 1;
  Offset _basePan = Offset.zero;
  Offset _baseFocal = Offset.zero;
  bool _dividerDrag = false;
  Offset _doubleTapPos = Offset.zero;
  Offset? _lensPoint;
  double _sFrom = 0.5, _sTo = 0.5;
  bool _animSlider = false;

  // Sinematik tur: kamera hotspot'lara sırayla yaklaşır
  bool _touring = false;
  Timer? _tourTimer;

  // Açılışta slider'ın bir kez süzülmesi (kaydırılabildiğini gösterir)
  late final AnimationController _intro;
  bool _userTouched = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _intro.addListener(() {
      if (_userTouched || !mounted) return;
      setState(() => _sliderValue = _introCurve.evaluate(_intro));
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !_userTouched) _intro.forward();
    });
    _zoomAnim.addListener(() {
      final t = Curves.easeOutCubic.transform(_zoomAnim.value);
      setState(() {
        _zoom = _zFrom + (_zTo - _zFrom) * t;
        _pan = Offset.lerp(_pFrom, _pTo, t)!;
        if (_animSlider) _sliderValue = _sFrom + (_sTo - _sFrom) * t;
      });
    });
    _resolveAspect(widget.beforeImageUrl, (a) => _oldAspect = a);
    _resolveAspect(widget.afterImageUrl, (a) => _newAspect = a);
  }

  static final TweenSequence<double> _introCurve = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.5,
        end: 0.18,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.18,
        end: 0.82,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.82,
        end: 0.5,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 20,
    ),
  ]);

  void _resolveAspect(String url, void Function(double) assign) {
    if (url.isEmpty) return;
    final stream = CachedNetworkImageProvider(
      url,
    ).resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      stream.removeListener(listener);
      if (!mounted) return;
      setState(() => assign(info.image.width / info.image.height));
    }, onError: (_, __) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  /// Fotoğraftaki (0-1) konumu, BoxFit.cover ile kırpılmış kutudaki piksel konumuna çevirir.
  static Offset _imageToBox(
    double ix,
    double iy,
    double a,
    double w,
    double h,
  ) {
    if (a > w / h) {
      final dw = a * h; // fotoğraf yüksekliğe sığar, yanlar taşar
      return Offset(ix * dw - (dw - w) / 2, iy * h);
    }
    final dh = w / a; // fotoğraf genişliğe sığar, alt/üst taşar
    return Offset(ix * w, iy * dh - (dh - h) / 2);
  }

  @override
  void didUpdateWidget(SplitSliderWidget old) {
    super.didUpdateWidget(old);
    // Bilgi kartı kapandıysa (çarpı ya da başka yere dokunma) yakınlaştırma yumuşakça geri alınır
    if (old.selectedHotspot != null &&
        widget.selectedHotspot == null &&
        !_touring &&
        _zoom > 1.05) {
      _resetZoom();
    }
  }

  @override
  void dispose() {
    final tc = widget.tourController;
    if (tc != null) Future.microtask(() => tc.sync(0, false, null));
    _intro.dispose();
    _zoomAnim.dispose();
    _tourTimer?.cancel();
    _activeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Offset _clampPan(Offset p, double z, double w, double h) =>
      Offset(p.dx.clamp(w - w * z, 0.0), p.dy.clamp(h - h * z, 0.0));

  void _animateZoomTo(double z, Offset pan, {double? slider}) {
    _zoomAnim.stop();
    _zFrom = _zoom;
    _pFrom = _pan;
    _zTo = z;
    _pTo = pan;
    _animSlider = slider != null;
    _sFrom = _sliderValue;
    _sTo = slider ?? _sliderValue;
    _zoomAnim.forward(from: 0);
  }

  void _resetZoom() => _animateZoomTo(1, Offset.zero);

  bool _isNewSide(Hotspot h) => h.targetSide.trim().toLowerCase() == 'before';

  /// Hotspot'un fotoğraf içindeki (yakınlaştırmasız) kutu konumu.
  Offset _hotspotContent(Hotspot h, double w, double hgt) {
    final aspect = _isNewSide(h) ? _newAspect : _oldAspect;
    return aspect == null
        ? Offset(h.xPercent * w, h.yPercent * hgt)
        : _imageToBox(h.xPercent, h.yPercent, aspect, w, hgt);
  }

  /// Kamerayı hotspot'a yaklaştırır (nokta, açılan bilgi kartının altında kalsın diye alt yarıya oturur).
  void _focusHotspot(
    Hotspot h,
    double w,
    double hgt, {
    double zoom = 2.2,
    bool moveDivider = false,
  }) {
    final c = _hotspotContent(h, w, hgt);
    final pan = _clampPan(Offset(w / 2, hgt * 0.64) - c * zoom, zoom, w, hgt);
    // Noktanın bulunduğu dönem görünsün: eski fotoğraf solda, güncel sağda
    final slider = moveDivider ? (_isNewSide(h) ? 0.04 : 0.96) : null;
    _animateZoomTo(zoom, pan, slider: slider);
  }

  double _lastW = 0, _lastH = 0;
  bool _tourSynced = false;

  void _syncTour() {
    final c = widget.tourController;
    if (c == null) return;
    final n = _tourStops.length;
    if (_tourSynced && c.stops == n && c.touring == _touring) return;
    _tourSynced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      c.sync(
        n,
        _touring,
        () => _touring ? _endTour(reset: true) : _startTour(_lastW, _lastH),
      );
    });
  }

  List<Hotspot> get _tourStops =>
      widget.hotspots.where((h) => !h.hasSubPlaceNavigation).take(6).toList();

  void _startTour(double w, double hgt) {
    final stops = _tourStops;
    if (stops.isEmpty) return;
    _userTouched = true;
    if (_intro.isAnimating) _intro.stop();
    HapticFeedback.mediumImpact();
    setState(() => _touring = true);
    _tourStep(0, stops, w, hgt);
  }

  void _tourStep(int i, List<Hotspot> stops, double w, double hgt) {
    if (!mounted || !_touring) return;
    if (i >= stops.length) {
      _endTour(reset: true);
      return;
    }
    _focusHotspot(stops[i], w, hgt, moveDivider: true);
    widget.onHotspotSelected?.call(stops[i]);
    _tourTimer?.cancel();
    _tourTimer = Timer(
      const Duration(milliseconds: 4200),
      () => _tourStep(i + 1, stops, w, hgt),
    );
  }

  void _endTour({required bool reset}) {
    _tourTimer?.cancel();
    if (!_touring) return;
    setState(() => _touring = false);
    widget.onHotspotSelected?.call(null);
    if (reset) {
      _animateZoomTo(1, Offset.zero, slider: 0.5);
    }
  }

  Matrix4 _matrix(double z, Offset pan) => Matrix4.identity()
    ..setEntry(0, 0, z)
    ..setEntry(1, 1, z)
    ..setEntry(0, 3, pan.dx)
    ..setEntry(1, 3, pan.dy);

  void _onScaleStart(ScaleStartDetails d, double w) {
    if (_touring) {
      _tourTimer?.cancel();
      setState(() => _touring = false);
    }
    _userTouched = true;
    if (_intro.isAnimating) _intro.stop();
    _zoomAnim.stop();
    _lastPointers = d.pointerCount;
    _baseZoom = _zoom;
    _basePan = _pan;
    _baseFocal = d.localFocalPoint;
    final dividerX = _sliderValue * w;
    // Yakınlaştırılmamışken her yerden, yakınlaştırılmışken yalnızca çizgiden tutunca çizgi oynar
    _dividerDrag =
        d.pointerCount == 1 &&
        (_zoom <= 1.02 || (d.localFocalPoint.dx - dividerX).abs() < 40);
  }

  void _onScaleUpdate(ScaleUpdateDetails d, double w, double h) {
    // Parmak sayısı değişince (ikinci parmak geldi / kalktı) taban değerleri yenilenir
    if (d.pointerCount != _lastPointers) {
      _lastPointers = d.pointerCount;
      _baseZoom = _zoom;
      _basePan = _pan;
      _baseFocal = d.localFocalPoint;
      _dividerDrag = false;
      return;
    }
    if (d.pointerCount >= 2) {
      final z = (_baseZoom * d.scale).clamp(1.0, _maxZoom);
      final contentFocal = (_baseFocal - _basePan) / _baseZoom;
      final pan = d.localFocalPoint - contentFocal * z;
      setState(() {
        _zoom = z;
        _pan = _clampPan(pan, z, w, h);
      });
    } else if (_dividerDrag) {
      final nv = (d.localFocalPoint.dx / w).clamp(0.0, 1.0);
      // Dörtte bir çizgilerini geçerken hafif titreşim
      if ((nv * 4).floor() != (_sliderValue * 4).floor()) {
        HapticFeedback.selectionClick();
      }
      _activeTimer?.cancel();
      _activeTimer = Timer(const Duration(milliseconds: 260), () {
        if (mounted) setState(() => _active = false);
      });
      setState(() {
        _sliderValue = nv;
        _active = true;
      });
    } else if (_zoom > 1.0) {
      final pan = _basePan + (d.localFocalPoint - _baseFocal);
      setState(() => _pan = _clampPan(pan, _zoom, w, h));
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_zoom < 1.03 && _zoom != 1) {
      setState(() {
        _zoom = 1;
        _pan = Offset.zero;
      });
    }
  }

  void _onDoubleTap(double w, double h) {
    if (_zoom > 1.05) {
      _resetZoom();
    } else {
      const z = 2.5;
      _animateZoomTo(z, _clampPan(_doubleTapPos * (1 - z), z, w, h));
    }
  }

  /// Eski ve yeni görseli verilen dönüşümle çizer; çizgi ekran koordinatlarında kırpar.
  Widget _scene(double w, double h, double dividerX, Matrix4 m) {
    Widget img(String url) => Transform(
      transform: m,
      child: SizedBox(
        width: w,
        height: h,
        child: AppNetworkImage(imageUrl: url, width: w, height: h),
      ),
    );
    return ClipRect(
      child: Stack(
        children: [
          img(widget.afterImageUrl), // sağ: güncel
          ClipRect(
            clipper: _LeftClipper(dividerX),
            child: img(widget.beforeImageUrl), // sol: tarihî
          ),
        ],
      ),
    );
  }

  /// Parmağın altını büyüten yuvarlak "zaman merceği"; içinde iki dönem de bölünmüş görünür.
  Widget _buildLens(double w, double h, double dividerX, Matrix4 sceneM) {
    final f = _lensPoint!;
    const r = _lensRadius;
    var c = Offset(f.dx.clamp(r + 8, w - r - 8), f.dy - r - 44);
    if (c.dy - r < 6) c = Offset(c.dx, f.dy + r + 44);
    final lensM = Matrix4.identity()
      ..setEntry(0, 0, _lensMagnify)
      ..setEntry(1, 1, _lensMagnify)
      ..setEntry(0, 3, r - _lensMagnify * f.dx)
      ..setEntry(1, 3, r - _lensMagnify * f.dy);
    return Stack(
      children: [
        // Parmağın altındaki odak noktası
        Positioned(
          left: f.dx - 7,
          top: f.dy - 7,
          child: IgnorePointer(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),
        Positioned(
          left: c.dx - r,
          top: c.dy - r,
          child: IgnorePointer(
            child: Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: 0,
                  minHeight: 0,
                  maxWidth: w,
                  maxHeight: h,
                  child: Transform(
                    transform: lensM,
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: _scene(w, h, dividerX, sceneM),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DarkCancel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final totalHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 340.0;
          _lastW = totalWidth;
          _lastH = totalHeight;
          _syncTour();
          final dividerX = _sliderValue * totalWidth;
          final sceneM = _matrix(_zoom, _pan);

          return Stack(
            children: [
              // 1. Karşılaştırma katmanı: çizgi + iki parmakla yakınlaştırma + çift dokunma + mercek
              Semantics(
                slider: true,
                label: context.t('a11y_slider'),
                value: '${(_sliderValue * 100).round()}%',
                increasedValue:
                    '${((_sliderValue + 0.1).clamp(0.0, 1.0) * 100).round()}%',
                decreasedValue:
                    '${((_sliderValue - 0.1).clamp(0.0, 1.0) * 100).round()}%',
                onIncrease: () => setState(() {
                  _userTouched = true;
                  _intro.stop();
                  _sliderValue = (_sliderValue + 0.1).clamp(0.0, 1.0);
                }),
                onDecrease: () => setState(() {
                  _userTouched = true;
                  _intro.stop();
                  _sliderValue = (_sliderValue - 0.1).clamp(0.0, 1.0);
                }),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (d) => _onScaleStart(d, totalWidth),
                  onScaleUpdate: (d) =>
                      _onScaleUpdate(d, totalWidth, totalHeight),
                  onScaleEnd: _onScaleEnd,
                  // Açık bir bilgi kartı varken fotoğrafın başka bir yerine dokunmak kartı kapatır
                  onTap: () {
                    if (widget.selectedHotspot != null && !_touring) {
                      widget.onHotspotSelected?.call(null);
                    }
                  },
                  onDoubleTapDown: (d) => _doubleTapPos = d.localPosition,
                  onDoubleTap: () => _onDoubleTap(totalWidth, totalHeight),
                  onLongPressStart: (d) {
                    HapticFeedback.mediumImpact();
                    setState(() => _lensPoint = d.localPosition);
                  },
                  onLongPressMoveUpdate: (d) =>
                      setState(() => _lensPoint = d.localPosition),
                  onLongPressEnd: (_) => setState(() => _lensPoint = null),
                  onLongPressCancel: () => setState(() => _lensPoint = null),
                  child: SizedBox(
                    width: totalWidth,
                    height: totalHeight,
                    child: _scene(totalWidth, totalHeight, dividerX, sceneM),
                  ),
                ),
              ),

              // 2. Cam efektli bölücü çizgi ve tutamaç
              Positioned(
                left: dividerX - 1.25,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.2, 0.8, 1.0],
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: dividerX - 28.0,
                top: (totalHeight * 0.5) - 28.0,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: _active ? 1.14 : 1.0,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    child: _buildGlassKnob(),
                  ),
                ),
              ),

              // 3. Sol alt: Dönem rozeti (cam)
              Positioned(
                left: 16,
                bottom: widget.bottomInset + 14,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: (_sliderValue > 0.12) ? 1.0 : 0.0,
                    child: _buildBadge(
                      widget.afterLabel,
                      tint: AppColors.primaryTealDark,
                    ),
                  ),
                ),
              ),

              // 4. Sağ alt: Bugün rozeti (cam)
              Positioned(
                right: 16,
                bottom: widget.bottomInset + 14,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: (_sliderValue < 0.88) ? 1.0 : 0.0,
                    child: _buildBadge(
                      widget.beforeLabel,
                      tint: AppColors.ciniCobalt,
                    ),
                  ),
                ),
              ),

              // 5b. Yakınlaştırınca: oran ve sıfırlama düğmesi
              Positioned(
                right: 16,
                top: MediaQuery.of(context).padding.top + 12 + widget.topOffset,
                child: IgnorePointer(
                  ignoring: _zoom <= 1.05,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _zoom > 1.05 ? 1 : 0,
                    child: Semantics(
                      button: true,
                      label: context.t('zoom_reset'),
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: _resetZoom,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.38),
                                  width: 0.9,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.zoom_out_map_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_zoom.toStringAsFixed(1)}×',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 6. Dinamik hotspot'lar (fotoğrafla birlikte hareket eder, boyutu sabit kalır)
              if (_showHotspots)
                ...widget.hotspots.map((hotspot) {
                  final isBeforeSide =
                      hotspot.targetSide.trim().toLowerCase() == 'before';
                  // 'after' hotspot'ları sol (eski) fotoğrafa, 'before' olanlar sağ (güncel) fotoğrafa aittir
                  final aspect = isBeforeSide ? _newAspect : _oldAspect;
                  final content = aspect == null
                      ? Offset(
                          hotspot.xPercent * totalWidth,
                          hotspot.yPercent * totalHeight,
                        )
                      : _imageToBox(
                          hotspot.xPercent,
                          hotspot.yPercent,
                          aspect,
                          totalWidth,
                          totalHeight,
                        );
                  final pos = content * _zoom + _pan;

                  // Kırpılan (görünmeyen) bölgeye düşen nokta gösterilmez
                  final inView =
                      pos.dx > 12 &&
                      pos.dx < totalWidth - 12 &&
                      pos.dy > 12 &&
                      pos.dy < totalHeight - 12;
                  final isVisible =
                      inView &&
                      (isBeforeSide ? pos.dx > dividerX : pos.dx < dividerX);
                  if (!isVisible) return const SizedBox.shrink();

                  return Positioned(
                    left: pos.dx - 16,
                    top: pos.dy - 16,
                    child: _buildAnimatedHotspot(
                      navCategory: hotspot.hasSubPlaceNavigation
                          ? widget.navCategories[hotspot.targetPlaceId]
                          : null,
                      label: context
                          .t('a11y_hotspot')
                          .replaceAll('{name}', hotspot.titleFor(context.isEn)),
                      onTap: () {
                        if (_touring) {
                          _tourTimer?.cancel();
                          setState(() => _touring = false);
                        }
                        // Dokununca kamera o noktaya yumuşakça yaklaşır
                        _focusHotspot(
                          hotspot,
                          totalWidth,
                          totalHeight,
                          zoom: _zoom > 1.9 ? _zoom : 1.9,
                        );
                        widget.onHotspotSelected?.call(hotspot);
                      },
                    ),
                  );
                }),

              // 7. Zaman merceği (basılı tutunca)
              if (_lensPoint != null)
                _buildLens(totalWidth, totalHeight, dividerX, sceneM),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedHotspot({
    required VoidCallback onTap,
    required String label,
    PlaceCategory? navCategory,
  }) {
    final navStyle = navCategory == null ? null : CategoryStyle.of(navCategory);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.25);
            final opacity = 0.35 - (_pulseController.value * 0.20);

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (navStyle?.color ?? Colors.white).withValues(
                        alpha: opacity.clamp(0.08, 0.4),
                      ),
                    ),
                  ),
                ),
                if (navStyle != null)
                  // Yönlendirme: gidilecek yapının kategori renginde, kategori simgeli daire
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: navStyle.color,
                      border: Border.all(color: Colors.white, width: 2.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: AppIcon(
                      navStyle.icon.replaceFirst('pin_', 'cat_'),
                      size: 17,
                      color: Colors.white,
                    ),
                  )
                else
                  // Bilgi noktası: beyaz daire, ortada teal nokta
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Buzlu cam görünümlü tutamaç: dıştaki halka nabız gibi atar, ortada iki ok vardır.
  Widget _buildGlassKnob() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + _pulseController.value * 0.28,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.42 - _pulseController.value * 0.34,
                    ),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.46),
                      Colors.white.withValues(alpha: 0.14),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, {required Color tint, IconData? trailing}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.38),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                Icon(trailing, size: 15, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double dividerX;
  const _LeftClipper(this.dividerX);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, dividerX, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.dividerX != dividerX;
}
