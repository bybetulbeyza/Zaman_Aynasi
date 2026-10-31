import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:before_after/before_after.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_network_image.dart';

class SplitSliderWidget extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final String beforeLabel;
  final String afterLabel;
  final List<Hotspot> hotspots;
  final ValueChanged<Hotspot>? onHotspotSelected;

  /// Bu kadar piksel alt kısım bilgi sayfasının altında kalır; butonlar bunun üstüne yerleşir.
  final double bottomInset;

  const SplitSliderWidget({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.beforeLabel = 'Bugün',
    this.afterLabel = 'Dönem',
    this.hotspots = const [],
    this.onHotspotSelected,
    this.bottomInset = 0,
  });

  @override
  State<SplitSliderWidget> createState() => _SplitSliderWidgetState();
}

class _SplitSliderWidgetState extends State<SplitSliderWidget>
    with SingleTickerProviderStateMixin {
  double _sliderValue = 0.5;
  bool _active = false; // kullanıcı slider'ı sürüklerken tutamaç büyür
  Timer? _activeTimer;
  bool _showHotspots = true;
  bool _coordinatePickerMode = false; // Koordinat yakalama anahtarı
  late AnimationController _pulseController;

  // Fotoğrafların en/boy oranları: hotspot konumları fotoğrafa göre tutulur, kutuya göre değil.
  double? _oldAspect; // sol taraf (image_before_url, 'after' hotspot'ları)
  double? _newAspect; // sağ taraf (image_after_url, 'before' hotspot'ları)

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

  /// Kutudaki dokunma noktasını fotoğraftaki (0-1) konuma çevirir ([_imageToBox]'un tersi).
  static Offset _boxToImage(
    double px,
    double py,
    double a,
    double w,
    double h,
  ) {
    if (a > w / h) {
      final dw = a * h;
      return Offset((px + (dw - w) / 2) / dw, py / h);
    }
    final dh = w / a;
    return Offset(px / w, (py + (dh - h) / 2) / dh);
  }

  @override
  void dispose() {
    _intro.dispose();
    _activeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 340.0;
        final dividerX = _sliderValue * totalWidth;

        return Stack(
          children: [
            // 1. Before-After Karşılaştırma Katmanı
            SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: BeforeAfter(
                value: _sliderValue,
                before: AppNetworkImage(
                  imageUrl: widget.afterImageUrl,
                  width: totalWidth,
                  height: totalHeight,
                ),
                after: AppNetworkImage(
                  imageUrl: widget.beforeImageUrl,
                  width: totalWidth,
                  height: totalHeight,
                ),
                onValueChanged: (val) {
                  if (!_coordinatePickerMode) {
                    _userTouched = true;
                    if (_intro.isAnimating) _intro.stop();
                    // Dörtte bir çizgilerini geçerken hafif titreşim
                    if ((val * 4).floor() != (_sliderValue * 4).floor()) {
                      HapticFeedback.selectionClick();
                    }
                    _activeTimer?.cancel();
                    _activeTimer = Timer(const Duration(milliseconds: 260), () {
                      if (mounted) setState(() => _active = false);
                    });
                    setState(() {
                      _sliderValue = val;
                      _active = true;
                    });
                  }
                },
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

            // 3. Sol üst: Dönem rozeti (cam)
            Positioned(
              left: 16,
              top: 68,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_sliderValue > 0.12) ? 1.0 : 0.0,
                child: _buildBadge(
                  widget.afterLabel,
                  tint: AppColors.primaryTealDark,
                ),
              ),
            ),

            // 4. Sağ üst: Bugün rozeti (cam)
            Positioned(
              right: 16,
              top: 68,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_sliderValue < 0.88) ? 1.0 : 0.0,
                child: _buildBadge(
                  widget.beforeLabel,
                  tint: AppColors.ciniCobalt,
                ),
              ),
            ),

            // 5. Dinamik Hotspot'lar
            if (_showHotspots && !_coordinatePickerMode)
              ...widget.hotspots.map((hotspot) {
                final isBeforeSide =
                    hotspot.targetSide.trim().toLowerCase() == 'before';
                // 'after' hotspot'ları sol (eski) fotoğrafa, 'before' olanlar sağ (güncel) fotoğrafa aittir
                final aspect = isBeforeSide ? _newAspect : _oldAspect;
                final pos = aspect == null
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
                    onTap: () {
                      if (widget.onHotspotSelected != null) {
                        widget.onHotspotSelected!(hotspot);
                      }
                    },
                  ),
                );
              }),

            // 6. En Üst Katman: KOORDİNAT YAKALAYICI PERDE (Aktifken dokunmaları doğrudan kapar)
            if (_coordinatePickerMode)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final side = (details.localPosition.dx < dividerX)
                        ? 'after'
                        : 'before';
                    final aspect = side == 'before' ? _newAspect : _oldAspect;
                    final img = aspect == null
                        ? Offset(
                            details.localPosition.dx / totalWidth,
                            details.localPosition.dy / totalHeight,
                          )
                        : _boxToImage(
                            details.localPosition.dx,
                            details.localPosition.dy,
                            aspect,
                            totalWidth,
                            totalHeight,
                          );
                    final x = img.dx.clamp(0.0, 1.0);
                    final y = img.dy.clamp(0.0, 1.0);

                    final xStr = x.toStringAsFixed(2);
                    final yStr = y.toStringAsFixed(2);

                    // 1. Terminale / Konsola yazdırır
                    debugPrint(
                      '📍 YENİ HOTSPOT -> x_percent: $xStr | y_percent: $yStr | target_side: $side',
                    );

                    // 2. Ekranda direkt bildirim olarak gösterir
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'x_percent: $xStr, y_percent: $yStr, side: $side',
                        ),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.ciniBordeaux,
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.15),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Nokta koymak istediğin yere tıkla',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 7. Modu Açıp Kapatma Butonu (Sol Alt Köşe)
            if (kDebugMode)
              Positioned(
                left: 12,
                bottom: widget.bottomInset + 12,
                child: FloatingActionButton.small(
                  heroTag: 'coordPickerBtn',
                  backgroundColor: _coordinatePickerMode
                      ? AppColors.ciniBordeaux
                      : Colors.white,
                  onPressed: () {
                    setState(() {
                      _coordinatePickerMode = !_coordinatePickerMode;
                    });
                  },
                  child: Icon(
                    _coordinatePickerMode
                        ? Icons.check_rounded
                        : Icons.add_location_alt_outlined,
                    color: _coordinatePickerMode
                        ? Colors.white
                        : AppColors.textDark,
                    size: 20,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedHotspot({required VoidCallback onTap}) {
    return GestureDetector(
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
                    color: Colors.white.withOpacity(opacity.clamp(0.08, 0.4)),
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
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

  Widget _buildBadge(String text, {required Color tint}) {
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
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}
