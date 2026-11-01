import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/l10n/app_lang.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/heritage_place.dart';
import 'slider_parts.dart';

/// Eserin 3B modeli: döndür, yakınlaştır, AR'da aç.
/// İki model de varsa aynı sayfada üst üste biner; sürüklenen çizginin solu tarihî, sağı günümüz
/// görünür ve kamera ikisinde birlikte hareket eder. Hotspot'lar modelin yüzeyine yapışır.
class Model3DView extends StatefulWidget {
  final String newUrl;
  final String oldUrl;
  final String name;
  final List<Hotspot> hotspots;
  final Hotspot? selected;
  final ValueChanged<Hotspot?> onHotspot;
  final double bottomInset;

  const Model3DView({
    super.key,
    required this.newUrl,
    required this.oldUrl,
    required this.name,
    required this.onHotspot,
    this.selected,
    this.hotspots = const [],
    this.bottomInset = 0,
  });

  static final _num = RegExp(r'^[-+0-9.eE\s]+$');

  @override
  State<Model3DView> createState() => _Model3DViewState();

  static String htmlEscapeAttr(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;');

  static List<double> _nums(String? s, List<double> fallback) {
    if (s == null || !_num.hasMatch(s)) return fallback;
    final v = s
        .trim()
        .split(RegExp(r'\s+'))
        .map(double.tryParse)
        .whereType<double>()
        .toList();
    return v.length == 3 ? v : fallback;
  }
}

class _Model3DViewState extends State<Model3DView>
    with SingleTickerProviderStateMixin {
  dynamic _web; // WebViewController (webview_flutter üzerinden gelir)
  double _zoom = 1;
  Timer? _tourTimer;
  bool _touring = false;
  int _tourIdx = 0;
  double _f = 0.5; // bölücü konumu (0..1), fotoğraf slider'ındaki gibi
  bool _active = false;
  bool _userTouched = false;
  bool _canAr = false;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

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

  @override
  void initState() {
    super.initState();
    _intro.addListener(() {
      if (_userTouched || !mounted) return;
      _setSplit(_introCurve.evaluate(_intro));
    });
    // Fotoğraf slider'ındaki gibi: açılışta çizgi kendiliğinden iki yana gider
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && !_userTouched && widget.oldUrl.isNotEmpty) {
        _intro.forward();
      }
    });
  }

  void _setSplit(double v) {
    setState(() => _f = v.clamp(0.0, 1.0));
    _js('window.zaSplit&&window.zaSplit($_f)');
  }

  List<Hotspot> get _valid => widget.hotspots
      .where((h) => Model3DView._num.hasMatch(h.modelPos ?? ''))
      .toList();

  void _js(String code) => _web?.runJavaScript(code);

  @override
  void didUpdateWidget(Model3DView old) {
    super.didUpdateWidget(old);
    if (widget.selected?.id == old.selected?.id) return;
    final sel = widget.selected;
    if (sel != null) {
      _js("window.zaFocus('${sel.id}')");
    } else {
      if (_touring) _stopTour(notify: false);
      _js('window.zaReset()');
    }
  }

  void _startTour() {
    final stops = _valid;
    if (stops.length < 2) return;
    setState(() {
      _touring = true;
      _tourIdx = 0;
    });
    widget.onHotspot(stops[0]);
    _tourTimer?.cancel();
    _tourTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _tourIdx++;
      if (_tourIdx >= stops.length) {
        _stopTour();
      } else {
        widget.onHotspot(stops[_tourIdx]);
      }
    });
  }

  void _stopTour({bool notify = true}) {
    _tourTimer?.cancel();
    if (mounted) setState(() => _touring = false);
    if (notify) widget.onHotspot(null);
  }

  @override
  void dispose() {
    _tourTimer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  String _hotspotHtml() {
    final b = StringBuffer()
      ..writeln('<button slot="ar-button" style="display:none"></button>');
    var n = 0;
    for (final h in _valid) {
      final normal = Model3DView._num.hasMatch(h.modelNormal ?? '')
          ? h.modelNormal!
          : '0 1 0';
      n++;
      b.writeln(
        '<button class="hs" slot="hotspot-$n" data-position="${h.modelPos}" '
        'data-normal="$normal" data-visibility-attribute="visible" '
        'aria-label="${Model3DView.htmlEscapeAttr(h.title)}" '
        'onclick="HotspotTap.postMessage(\'${h.id}\')">$n</button>',
      );
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final newUrl = widget.newUrl;
    final oldUrl = widget.oldUrl;
    final both = newUrl.isNotEmpty && oldUrl.isNotEmpty;
    final src = newUrl.isNotEmpty ? newUrl : oldUrl;
    final cfg = jsonEncode({
      'oldSrc': both ? oldUrl : '',
      'single': both ? '' : (newUrl.isNotEmpty ? 'new' : 'old'),
      'hs': [
        for (final h in _valid)
          {
            'id': h.id.toString(),
            'p': Model3DView._nums(h.modelPos, [0, 10, 0]),
            'n': Model3DView._nums(h.modelNormal, [0, 0, -1]),
          },
      ],
    });
    final top = MediaQuery.of(context).padding.top + 12;
    final canTour = _valid.length >= 2;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final dividerX = _f * w;
        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: widget.bottomInset),
              child: ModelViewer(
                key: ValueKey('$newUrl|$oldUrl|${widget.hotspots.length}'),
                src: src,
                alt: widget.name,
                backgroundColor: Colors.transparent,
                cameraControls: true,
                disableZoom: false,
                ar: true,
                arModes: const ['scene-viewer', 'quick-look', 'webxr'],
                interactionPrompt: InteractionPrompt.none,
                shadowIntensity: 1,
                exposure: 1.05,
                cameraOrbit: '35deg 70deg auto',
                innerModelViewerHtml: _hotspotHtml(),
                relatedCss: _css,
                relatedJs: _js_.replaceFirst('__CFG__', cfg),
                onWebViewCreated: (c) => _web = c,
                javascriptChannels: {
                  JavascriptChannel(
                    'HotspotTap',
                    onMessageReceived: (m) {
                      for (final hs in widget.hotspots) {
                        if (hs.id.toString() == m.message) {
                          widget.onHotspot(hs);
                          break;
                        }
                      }
                    },
                  ),
                  JavascriptChannel(
                    'ZoomCh',
                    onMessageReceived: (m) {
                      final msg = m.message;
                      if (msg == 'ready') {
                        _js('window.zaSplit&&window.zaSplit($_f)');
                      } else if (msg == 'ar') {
                        if (mounted) setState(() => _canAr = true);
                      } else {
                        final z = double.tryParse(msg);
                        if (z != null && (z - _zoom).abs() > 0.05 && mounted) {
                          setState(() => _zoom = z);
                        }
                      }
                    },
                  ),
                },
              ),
            ),

            if (both) ...[
              // Cam efektli bölücü çizgi ve tutamaç (fotoğraf slider'ıyla aynı)
              Positioned(
                left: dividerX - 1.25,
                top: 0,
                bottom: widget.bottomInset,
                child: const GlassDividerLine(),
              ),
              Positioned(
                left: dividerX - 28,
                top: (h - widget.bottomInset) * 0.5 - 28,
                child: GlassKnob(active: _active),
              ),
              // Tutamaçtan sürüklenir (model başka yerde döndürülür)
              Positioned(
                left: dividerX - 28,
                top: (h - widget.bottomInset) * 0.5 - 70,
                width: 56,
                height: 140,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) {
                    _userTouched = true;
                    if (_intro.isAnimating) _intro.stop();
                    HapticFeedback.mediumImpact();
                    setState(() => _active = true);
                  },
                  onHorizontalDragUpdate: (d) => _setSplit(_f + d.delta.dx / w),
                  onHorizontalDragEnd: (_) => setState(() => _active = false),
                  onHorizontalDragCancel: () => setState(() => _active = false),
                ),
              ),
              Positioned(
                left: 16,
                bottom: widget.bottomInset + 14,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _f > 0.12 ? 1.0 : 0.0,
                    child: GlassBadge(
                      context.t('period_label'),
                      tint: AppColors.primaryTealDark,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: widget.bottomInset + 14,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _f < 0.88 ? 1.0 : 0.0,
                    child: GlassBadge(
                      context.t('today_label'),
                      tint: AppColors.ciniCobalt,
                    ),
                  ),
                ),
              ),
            ],

            // AR (cihaz destekliyorsa), geri okun altında
            if (_canAr)
              Positioned(
                left: 14,
                top: top + 52,
                child: GlassPill(
                  onTap: () => _js('window.zaAR&&window.zaAR()'),
                  label: 'AR',
                  icon: Icons.view_in_ar_rounded,
                ),
              ),

            // Turu başlat / durdur (fotoğraf slider'ındaki gibi)
            if (canTour)
              Positioned(
                right: 16,
                top: top + 46,
                child: GlassPill(
                  onTap: _touring ? _stopTour : _startTour,
                  label: _touring
                      ? context.t('tour_stop')
                      : context.t('tour_start'),
                  icon: _touring
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  text: _touring
                      ? context.t('tour_stop')
                      : context.t('tour_start'),
                  tint: _touring ? AppColors.ciniBordeaux : null,
                ),
              ),

            // Yakınlaşınca: oran ve sıfırlama
            Positioned(
              right: 16,
              top: top + (canTour ? 92 : 46),
              child: IgnorePointer(
                ignoring: _zoom <= 1.05,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _zoom > 1.05 ? 1 : 0,
                  child: GlassPill(
                    onTap: () {
                      if (_touring) _stopTour(notify: false);
                      widget.onHotspot(null);
                      _js('window.zaReset()');
                    },
                    label: context.t('zoom_reset'),
                    icon: Icons.zoom_out_map_rounded,
                    text: '${_zoom.toStringAsFixed(1)}×',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static const _css = r'''
html, body { overflow: hidden; background: transparent; }
.hs {
  position: relative; width: 26px; height: 26px; border-radius: 50%; padding: 0;
  border: 0; background: rgba(255,255,255,.96); cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,.4);
  animation: hspulse 1.8s ease-out infinite;
}
.hs::after {
  content: ''; position: absolute; left: 7px; top: 7px; width: 12px; height: 12px;
  border-radius: 50%; background: #17a2a4;
}
@keyframes hspulse {
  0% { box-shadow: 0 0 0 0 rgba(255,255,255,.65), 0 2px 8px rgba(0,0,0,.4); }
  70% { box-shadow: 0 0 0 11px rgba(255,255,255,0), 0 2px 8px rgba(0,0,0,.4); }
  100% { box-shadow: 0 0 0 0 rgba(255,255,255,0), 0 2px 8px rgba(0,0,0,.4); }
}
''';

  static const _js_ = r'''
(function () {
  const CFG = __CFG__;
  const OLD_BG = 'linear-gradient(#f1e3c8,#d9be92)';
  const NEW_BG = 'linear-gradient(#ddebf2,#f3efe6)';
  const DEG = Math.PI / 180;
  customElements.whenDefined('model-viewer').then(function () {
    const nw = document.querySelector('model-viewer');
    const fill = 'position:absolute;left:0;top:0;width:100%;height:100%;';
    nw.style.cssText = fill;
    document.body.style.position = 'relative';
    nw.style.background = CFG.single === 'old' ? OLD_BG : NEW_BG;
    let od = null;
    if (CFG.oldSrc) {
      od = document.createElement('model-viewer');
      for (const a of nw.attributes) {
        if (a.name !== 'src' && a.name !== 'style' && a.name !== 'ar' && a.name !== 'ar-modes') {
          od.setAttribute(a.name, a.value);
        }
      }
      od.setAttribute('src', CFG.oldSrc);
      od.innerHTML = nw.innerHTML;
      od.style.cssText = fill + 'background:' + OLD_BG + ';';
      nw.after(od);
    }
    const els = od ? [nw, od] : [nw];
    els.forEach(function (e) { e.setAttribute('interpolation-decay', '90'); });

    // --- Kamera sınırları: zemin altına inilmez, çok uzaklaşılmaz
    let base = 60, home = null, homeT = null;
    function limits() {
      const r = nw.getCameraOrbit().radius;
      if (r > 0) base = r;
      const minR = Math.max(8, base * 0.12) + 'm', maxR = (base * 1.5) + 'm';
      els.forEach(function (e) {
        e.minCameraOrbit = 'auto 15deg ' + minR;
        e.maxCameraOrbit = 'auto 84deg ' + maxR;
      });
    }
    nw.addEventListener('load', function () {
      limits();
      const o = nw.getCameraOrbit(), t = nw.getCameraTarget();
      home = { th: o.theta, ph: Math.min(o.phi, 84 * DEG), r: o.radius };
      homeT = { x: t.x, y: t.y, z: t.z };
    });
    function clampTarget(e) {
      const t = e.getCameraTarget();
      const x = Math.min(20, Math.max(-20, t.x)), y = Math.min(20, Math.max(2, t.y)), z = Math.min(20, Math.max(-20, t.z));
      if (x !== t.x || y !== t.y || z !== t.z) {
        e.cameraTarget = x + 'm ' + y + 'm ' + z + 'm';
        e.jumpCameraToGoal();
      }
    }

    // --- Tarihî / günümüz ayırıcı (çizgiyi Flutter çizer, burada yalnızca kırpma)
    let f = 0.5;
    function apply() {
      if (!od) return;
      od.style.clipPath = 'inset(0 ' + ((1 - f) * 100) + '% 0 0)';
      const x = f * window.innerWidth;
      for (const b of od.querySelectorAll('.hs')) {
        const r = b.getBoundingClientRect();
        b.style.visibility = (r.left + r.width / 2) < x ? 'visible' : 'hidden';
      }
      for (const b of nw.querySelectorAll('.hs')) {
        const r = b.getBoundingClientRect();
        b.style.visibility = (r.left + r.width / 2) >= x ? 'visible' : 'hidden';
      }
    }
    window.zaSplit = function (v) { f = v; apply(); };
    apply();
    window.zaAR = function () { try { nw.activateAR(); } catch (e) {} };
    if (nw.canActivateAR) ZoomCh.postMessage('ar');
    nw.addEventListener('ar-status', function () { if (nw.canActivateAR) ZoomCh.postMessage('ar'); });
    nw.addEventListener('load', function () { if (nw.canActivateAR) ZoomCh.postMessage('ar'); });
    ZoomCh.postMessage('ready');

    // --- Kamerayı iki modelde birlikte hareket ettir
    let active = null, until = 0, lastZ = 0;
    function mark(el) { return function (e) {
      if (e.detail && e.detail.source === 'user-interaction') { active = el; until = performance.now() + 1800; }
      const now = performance.now();
      if (now - lastZ > 120) {
        lastZ = now;
        const r = el.getCameraOrbit().radius;
        if (r > 0 && home) ZoomCh.postMessage(String(Math.round(home.r / r * 10) / 10));
      }
    }; }
    els.forEach(function (e) { e.addEventListener('camera-change', mark(e)); });
    function copy(a, b) {
      const o = a.getCameraOrbit(), t = a.getCameraTarget();
      b.cameraOrbit = o.theta + 'rad ' + o.phi + 'rad ' + o.radius + 'm';
      b.cameraTarget = t.x + 'm ' + t.y + 'm ' + t.z + 'm';
      b.jumpCameraToGoal();
    }
    function loop(now) {
      if (active && now < until) {
        clampTarget(active);
        if (od) copy(active, active === nw ? od : nw);
        apply();
      }
      requestAnimationFrame(loop);
    }
    requestAnimationFrame(loop);

    // --- Uçuş: ikisine de aynı hedef verilir
    function fly(th, ph, r, tx, ty, tz) {
      active = null;
      els.forEach(function (e) {
        e.cameraOrbit = th + 'rad ' + ph + 'rad ' + r + 'm';
        e.cameraTarget = tx + 'm ' + ty + 'm ' + tz + 'm';
      });
      setTimeout(apply, 120); setTimeout(apply, 600); setTimeout(apply, 1400);
    }
    window.zaReset = function () {
      if (!home) return;
      fly(home.th, home.ph, home.r, homeT.x, homeT.y, homeT.z);
    };
    window.zaFocus = function (id) {
      let h = null;
      for (const x of CFG.hs) if (x.id === id) h = x;
      if (!h || !home) return;
      const n = h.n, th = Math.atan2(n[0], n[2]);
      const ph = Math.min(84 * DEG, Math.max(55 * DEG, Math.acos(Math.max(-1, Math.min(1, n[1])))));
      fly(th, ph, Math.max(10, home.r * 0.38), h.p[0], Math.max(2, h.p[1]), h.p[2]);
    };

    // --- Çift dokunuş: yakınlaş / uzaklaş
    let lt = 0, lx = 0, ly = 0, dx = 0, dy = 0;
    document.addEventListener('pointerdown', function (e) { dx = e.clientX; dy = e.clientY; }, true);
    document.addEventListener('pointerup', function (e) {
      if (e.target.closest && (e.target.closest('.hs'))) return;
      if (Math.hypot(e.clientX - dx, e.clientY - dy) > 10) return;
      const now = performance.now();
      if (now - lt < 320 && Math.hypot(e.clientX - lx, e.clientY - ly) < 30 && home) {
        const o = nw.getCameraOrbit();
        if (o.radius < home.r * 0.8) window.zaReset();
        else {
          const t = nw.getCameraTarget();
          fly(o.theta, o.phi, Math.max(10, home.r * 0.45), t.x, t.y, t.z);
        }
        lt = 0;
      } else { lt = now; lx = e.clientX; ly = e.clientY; }
    }, true);
  });
})();
''';
}
