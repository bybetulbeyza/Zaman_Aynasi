import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/features.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';
import '../../../data/repositories/heritage_repository.dart';
import '../../../data/repositories/yadigar_repository.dart';
import '../../../core/constants/app_theme.dart';
import '../common/dark_cancel.dart';
import 'yadigar_sprites.dart';

/// Uygulamanın diğer yerlerinden Yadigâr'a gelen olaylar.
class YadigarEvents {
  YadigarEvents._();

  /// Mühür kutlaması kapanınca artar; Yadigâr seviner.
  static final ValueNotifier<int> celebrate = ValueNotifier(0);

  static void stampCelebrated() => celebrate.value++;
}

/// Yadigâr'ı geçici olarak gizleyen durumlar, sekmeye göre (ör. QR kamerası açık,
/// haritada eser kartı açık). Ekranlar build sırasında bildirir; güncelleme kare
/// sonrasına ertelenir.
class YadigarVisibility {
  YadigarVisibility._();

  static final ValueNotifier<Set<int>> hiddenTabs = ValueNotifier(<int>{});

  static void report(int tab, bool hide) {
    if (hiddenTabs.value.contains(tab) == hide) return;
    scheduleMicrotask(() {
      final next = {...hiddenTabs.value};
      hide ? next.add(tab) : next.remove(tab);
      hiddenTabs.value = next;
    });
  }
}

enum YadigarState {
  greeting,
  idle,
  lookingUp,
  celebrating,
  takingPaper,
  reading,
}

/// Ana sekmelerde sağ altta duran rehber karakter. Dokununca çantasından kâğıt çıkarır;
/// kâğıt açılınca rastgele bir eserin kısa bilgisini gösteren küçük bir kutu belirir.
/// Kutuya dokunan o eserin sayfasına gider, çarpıyla kapatılır.
class YadigarWidget extends StatefulWidget {
  /// false iken karakter gizlenir, animasyonu durur ve açık kutu kapanır.
  final bool visible;

  /// Seçili sekme; değişince Yadigâr bir kez yukarı bakar.
  final int tab;

  /// Kutudaki esere dokununca çağrılır.
  final ValueChanged<HeritagePlace> onOpenPlace;

  /// Karakterin görünen yüksekliği (mantıksal piksel). Dokunma alanı biraz daha büyüktür.
  final double height;

  const YadigarWidget({
    super.key,
    required this.visible,
    required this.tab,
    required this.onOpenPlace,
    this.height = 156,
  });

  @override
  State<YadigarWidget> createState() => _YadigarWidgetState();
}

class _YadigarWidgetState extends State<YadigarWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _pad = 8.0;

  /// Videolara göre oynatma hızı (1 = özgün hız).
  static const double _speed = 1.7;

  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  final ValueNotifier<int> _repaint = ValueNotifier(0);
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final math.Random _rnd = math.Random();

  YadigarState _state = YadigarState.idle;
  ui.Image? _img; // geçerli klibin atlası (kopya)
  YadigarClip? _imgClip;
  ui.Image? _fadeImg; // kutu kapanınca solarak kaybolan son kare
  Rect? _fadeRect;
  int _loadToken = 0;
  int _fi = 0; // gösterilen kare

  Duration _last = Duration.zero;
  double _clipTime = 0; // saniye
  bool _clipReady = false;
  bool _greeted = false;

  bool _pendingLookUp = false;
  bool _pendingCelebrate = false;

  bool _cardOpen = false;

  /// "Bir sırrım var, dokun!" balonu: kullanıcı Yadigâr'a ilk kez dokunana kadar,
  /// her açılışta selamlamanın ardından birkaç saniye görünür.
  static const _kTapped = 'yadigar_tapped';
  bool _everTapped = true;
  bool _hint = false;
  Timer? _hintTimer;
  HeritagePlace? _pick;
  String?
  _pickText; // "Biliyor muydunuz?" bilgisi (yoksa kısa açıklama gösterilir)
  String? _lastText;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    YadigarEvents.celebrate.addListener(_onCelebrate);
    _fade.addListener(_bump);
    SharedPreferences.getInstance()
        .then((p) => _everTapped = p.getBool(_kTapped) ?? false)
        .catchError((_) => false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeGreet());
  }

  void _maybeGreet() {
    if (!mounted) return;
    if (!_greeted && widget.visible) {
      _greeted = true;
      _play(YadigarState.greeting);
    } else if (_img == null) {
      _play(YadigarState.idle);
    }
  }

  @override
  void didUpdateWidget(YadigarWidget old) {
    super.didUpdateWidget(old);
    if (old.visible != widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!widget.visible) {
          if (_cardOpen || _state == YadigarState.takingPaper) {
            _closeCard(animate: false);
          }
        } else {
          _maybeGreet();
        }
        _syncTicker();
      });
    } else if (old.tab != widget.tab && widget.visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _request(YadigarState.lookingUp);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _syncTicker();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    YadigarEvents.celebrate.removeListener(_onCelebrate);
    _ticker.dispose();
    _fade.dispose();
    _repaint.dispose();
    _hintTimer?.cancel();
    _img?.dispose();
    _fadeImg?.dispose();
    super.dispose();
  }

  // ---------- Durumlar ----------

  void _onCelebrate() {
    if (!mounted) return;
    _request(YadigarState.celebrating);
  }

  /// Tek seferlik bir hareket ister; meşgulse sıraya alır. Kutu açıkken gelen sevinç ve
  /// bakış okumayı kesmez, kutu kapanınca oynar.
  void _request(YadigarState s) {
    final busy =
        _cardOpen ||
        _state == YadigarState.takingPaper ||
        _state == YadigarState.reading ||
        _state == YadigarState.greeting ||
        _state == YadigarState.celebrating;
    if (busy) {
      if (s == YadigarState.celebrating) _pendingCelebrate = true;
      if (s == YadigarState.lookingUp) _pendingLookUp = true;
      return;
    }
    _play(s);
  }

  void _next() {
    if (_pendingCelebrate) {
      _pendingCelebrate = false;
      _play(YadigarState.celebrating);
    } else if (_pendingLookUp) {
      _pendingLookUp = false;
      _play(YadigarState.lookingUp);
    } else {
      _play(YadigarState.idle);
    }
  }

  static YadigarClip _clipOf(YadigarState s) => switch (s) {
    YadigarState.greeting => YadigarClip.greet,
    YadigarState.idle => YadigarClip.idle,
    YadigarState.lookingUp => YadigarClip.lookUp,
    YadigarState.celebrating => YadigarClip.celebrate,
    YadigarState.takingPaper => YadigarClip.paperTake,
    YadigarState.reading => YadigarClip.paperRead,
  };

  Future<void> _play(YadigarState s) async {
    if (!mounted) return;
    // Hareket azaltma: tek seferlik hareketler atlanır, sabit kare gösterilir
    if (_reduceMotion) {
      if (s == YadigarState.takingPaper) s = YadigarState.reading;
      if (s != YadigarState.reading) s = YadigarState.idle;
    }
    _state = s;
    _clipTime = 0;
    _clipReady = false;
    final clip = _clipOf(s);
    final token = ++_loadToken;
    if (_imgClip != clip) {
      final img = await YadigarSprites.load(clip);
      if (!mounted || token != _loadToken) {
        img.dispose();
        return;
      }
      _img?.dispose();
      _img = img;
      _imgClip = clip;
    }
    _clipReady = true;
    _fi = 0;
    _bump();
    if (s == YadigarState.reading && !_cardOpen) _showCard();
    _syncTicker();
  }

  void _syncTicker() {
    final run =
        mounted &&
        widget.visible &&
        !_reduceMotion &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    // Uzun duraklamadan sonra büyük sıçrama olmasın
    final dt = math.min(0.1, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    if (!_clipReady) return;
    _clipTime += dt * _speed;
    final clip = _clipOf(_state);
    var i = (_clipTime * YadigarSprites.fps).floor();
    final loops = _state == YadigarState.idle || _state == YadigarState.reading;
    if (loops) {
      i %= clip.frames;
    } else if (i >= clip.frames) {
      if (_state == YadigarState.takingPaper) {
        _play(YadigarState.reading);
      } else {
        if (_state == YadigarState.greeting) _showHint();
        _next();
      }
      return;
    }
    if (_state == YadigarState.takingPaper &&
        !_cardOpen &&
        i >= YadigarSprites.paperOpenFrame) {
      _showCard();
    }
    if (i != _fi) {
      _fi = i;
      _bump();
    }
  }

  // ---------- Kutu ----------

  void _showHint() {
    if (_everTapped || !mounted || !widget.visible) return;
    setState(() => _hint = true);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 4500), _hideHint);
  }

  void _hideHint() {
    _hintTimer?.cancel();
    if (mounted && _hint) setState(() => _hint = false);
  }

  void _onTap() {
    _hideHint();
    if (!_everTapped) {
      _everTapped = true;
      SharedPreferences.getInstance()
          .then((p) => p.setBool(_kTapped, true))
          .catchError((_) => false);
    }
    if (_state == YadigarState.takingPaper) return;
    // Kutu açıkken Yadigâr'a dokunmak yeni bir bilgi getirir (kâğıt yeniden çıkarılmaz)
    if (_cardOpen) {
      _pickRandom();
      return;
    }
    _pendingLookUp = false; // dokunma, bekleyen bakıştan önceliklidir
    _pick = null;
    _pickText = null;
    _play(YadigarState.takingPaper);
    _pickRandom();
  }

  /// Rastgele bir bilgi seçer (aynı bilgi arka arkaya gelmez). Bilgi tablosu yoksa
  /// rastgele bir eserin kısa açıklaması kullanılır.
  Future<void> _pickRandom() async {
    try {
      final en = context.isEn;
      final results = await Future.wait([
        HeritageRepository().getPlacesCached(),
        YadigarRepository.facts(),
      ]);
      if (!mounted) return;
      final places = results[0] as List<HeritagePlace>;
      final facts = (results[1] as List<YadigarFact>)
          .where((f) => places.any((p) => p.id == f.placeId))
          .where((f) => f.textFor(en) != _lastText)
          .toList();
      if (facts.isNotEmpty) {
        final f = facts[_rnd.nextInt(facts.length)];
        final text = f.textFor(en);
        _lastText = text;
        setState(() {
          _pick = places.firstWhere((p) => p.id == f.placeId);
          _pickText = text;
        });
        return;
      }
      final pool = places
          .where((p) => p.descriptionFor(en).trim().isNotEmpty)
          .where((p) => _YadigarCard.shortOf(p.descriptionFor(en)) != _lastText)
          .toList();
      if (pool.isEmpty) return;
      final p = pool[_rnd.nextInt(pool.length)];
      _lastText = _YadigarCard.shortOf(p.descriptionFor(en));
      setState(() {
        _pick = p;
        _pickText = _lastText;
      });
    } catch (_) {
      // Veri alınamazsa kutu boş durum metnini gösterir
    }
  }

  void _showCard() {
    setState(() => _cardOpen = true);
    _portal.show();
  }

  void _closeCard({bool animate = true}) {
    if (!_cardOpen && _state != YadigarState.takingPaper) return;
    // Kâğıdı geri koyma hareketi yok: son kare kısa bir geçişle beklemeye karışır
    if (animate && _img != null && !_reduceMotion) {
      _fadeImg?.dispose();
      _fadeImg = _img!.clone();
      _fadeRect = YadigarSprites.frameRect(_fi);
      _fade.forward(from: 0);
    }
    setState(() => _cardOpen = false);
    _portal.hide();
    _next();
  }

  void _openPick() {
    final p = _pick;
    if (p == null) return;
    _closeCard(animate: false);
    widget.onOpenPlace(p);
  }

  void _bump() => _repaint.value++;

  // ---------- Çizim ----------

  @override
  Widget build(BuildContext context) {
    if (!AppFeatures.yadigar) return const SizedBox.shrink();
    final h = widget.height;
    final w = h * YadigarSprites.frameW / YadigarSprites.frameH;
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: _buildCardOverlay,
          child: CompositedTransformTarget(
            link: _link,
            child: Semantics(
              button: true,
              label: context.t('yadigar_label'),
              excludeSemantics: true,
              onTap: _onTap,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(_pad),
                      child: SizedBox(
                        width: w,
                        height: h,
                        // Karakter koyu modda da özgün renginde kalır
                        child: DarkCancel(
                          child: CustomPaint(
                            painter: _SpritePainter(
                              repaint: _repaint,
                              frame: () => _fi,
                              image: () => _img,
                              fadeImage: () =>
                                  _fade.isAnimating ? _fadeImg : null,
                              fadeRect: () => _fadeRect,
                              fadeT: () => _fade.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // İpucu balonu: karakterin solunda, başı hizasında
                    Positioned(
                      right: w + _pad - 6,
                      top: h * 0.08,
                      child: IgnorePointer(
                        child: AnimatedSlide(
                          offset: _hint ? Offset.zero : const Offset(0.08, 0),
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: _hint ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: _HintBubble(text: context.t('yadigar_hint')),
                          ),
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

  Widget _buildCardOverlay(BuildContext context) {
    final mq = MediaQuery.of(context);
    final box = this.context.findRenderObject() as RenderBox?;
    final top = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero).dy
        : mq.size.height / 2;
    final maxH = math.max(150.0, top - mq.padding.top - 24);
    final maxW = math.min(300.0, mq.size.width - 32);
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topRight,
        followerAnchor: Alignment.bottomRight,
        offset: const Offset(-_pad, 6),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
          child: _YadigarCard(
            place: _pick,
            text: _pickText,
            onOpen: _openPick,
            onClose: _closeCard,
          ),
        ),
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final int Function() frame;
  final ui.Image? Function() image;
  final ui.Image? Function() fadeImage;
  final Rect? Function() fadeRect;
  final double Function() fadeT;

  _SpritePainter({
    required Listenable repaint,
    required this.frame,
    required this.image,
    required this.fadeImage,
    required this.fadeRect,
    required this.fadeT,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    final img = image();
    if (img != null) {
      canvas.drawImageRect(
        img,
        YadigarSprites.frameRect(frame()),
        dst,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final f = fadeImage();
    final r = fadeRect();
    if (f != null && r != null) {
      canvas.drawImageRect(
        f,
        r,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(0, 0, 0, 1 - fadeT()),
      );
    }
  }

  @override
  bool shouldRepaint(_SpritePainter old) => true;
}

/// Kâğıt görünümlü küçük kutu: "Bunu biliyor muydunuz?" başlığı ve kısa bilgi.
/// Kutunun tamamı ve alttaki "Eseri keşfet" düğmesi eserin sayfasını açar; çarpı kapatır.
class _YadigarCard extends StatelessWidget {
  final HeritagePlace? place;
  final String? text;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const _YadigarCard({
    required this.place,
    required this.text,
    required this.onOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final p = place;
    const ink = Color(0xFF2E2922);
    final body = (p == null || text == null)
        ? context.t('yadigar_empty')
        : text!;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: const Color(0xFFFBF6EA),
        elevation: 6,
        shadowColor: const Color(0x55402A14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2D7C3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: p == null ? null : onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kanca başlık + kapatma
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t('yadigar_hook'),
                        style: const TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onClose,
                        tooltip: context.t('yadigar_close'),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SingleChildScrollView(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          body,
                          key: ValueKey(body),
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.42,
                            color: ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (p != null) ...[
                  const SizedBox(height: 10),
                  // Dokunulabilir olduğu açıkça görünsün: dolu, ok simgeli düğme
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: onOpen,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(context.t('yadigar_go')),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kısa açıklamanın ilk cümlesi (çok kısaysa ilk iki cümle).
  static String shortOf(String s) {
    final parts = s
        .trim()
        // Yalnızca küçük harften sonraki noktada ve büyük harften önce böl
        // ("15. yüzyıl", "II. Murad" bölünmesin)
        .split(RegExp(r'(?<=[a-zçğıöşüâîû)][.!?])\s+(?=[A-ZÇĞİÖŞÜÂÎ])'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return s;
    if (parts.first.length < 70 && parts.length > 1) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.first;
  }
}

/// Yadigâr'ın konuşma balonu: sağda karaktere doğru küçük bir kuyruk.
class _HintBubble extends StatelessWidget {
  final String text;
  const _HintBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 190),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryTeal, width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33402A14),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryTeal,
                height: 1.25,
              ),
            ),
          ),
          CustomPaint(size: const Size(9, 14), painter: _TailPainter()),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFBF6EA));
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height),
      Paint()
        ..color = AppColors.primaryTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}
