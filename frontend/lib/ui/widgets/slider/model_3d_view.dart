import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/l10n/app_lang.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/heritage_place.dart';

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

class _Model3DViewState extends State<Model3DView> {
  dynamic _web; // WebViewController (webview_flutter üzerinden gelir)
  double _zoom = 1;
  Timer? _tourTimer;
  bool _touring = false;
  int _tourIdx = 0;

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
    super.dispose();
  }

  String _hotspotHtml() {
    final b = StringBuffer();
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
      'oldLabel': context.t('model_old'),
      'newLabel': context.t('today_label'),
      'botPad': widget.bottomInset + 64,
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
                  for (final h in widget.hotspots) {
                    if (h.id.toString() == m.message) {
                      widget.onHotspot(h);
                      break;
                    }
                  }
                },
              ),
              JavascriptChannel(
                'ZoomCh',
                onMessageReceived: (m) {
                  final z = double.tryParse(m.message);
                  if (z != null && (z - _zoom).abs() > 0.05 && mounted) {
                    setState(() => _zoom = z);
                  }
                },
              ),
            },
          ),
        ),
        // Turu başlat / durdur (fotoğraf slider'ındaki gibi)
        if (canTour)
          Positioned(
            right: 16,
            top: top + 46,
            child: _glass(
              onTap: _touring ? _stopTour : _startTour,
              label: _touring
                  ? context.t('tour_stop')
                  : context.t('tour_start'),
              icon: _touring ? Icons.stop_rounded : Icons.play_arrow_rounded,
              text: _touring ? context.t('tour_stop') : context.t('tour_start'),
              tint: _touring ? AppColors.ciniBordeaux : null,
            ),
          ),
        // Yakınlaşınca oran + sıfırla
        Positioned(
          right: 16,
          top: top + (canTour ? 92 : 46),
          child: IgnorePointer(
            ignoring: _zoom <= 1.05,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _zoom > 1.05 ? 1 : 0,
              child: _glass(
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
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.bottomInset + 14,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.t('model_hint'),
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glass({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    required String text,
    Color? tint,
  }) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tint != null
                    ? tint.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.38),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    text,
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
    );
  }

  static const _css = r'''
html, body { overflow: hidden; background: transparent; }
.hs {
  width: 30px; height: 30px; border-radius: 50%;
  border: 2.5px solid #fff; background: #17a2a4; color: #fff;
  font: 700 13px sans-serif; padding: 0; cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,.45);
  animation: hspulse 2.2s ease-out infinite;
}
@keyframes hspulse {
  0% { box-shadow: 0 0 0 0 rgba(23,162,164,.6), 0 2px 8px rgba(0,0,0,.45); }
  70% { box-shadow: 0 0 0 12px rgba(23,162,164,0), 0 2px 8px rgba(0,0,0,.45); }
  100% { box-shadow: 0 0 0 0 rgba(23,162,164,0), 0 2px 8px rgba(0,0,0,.45); }
}
.lbl {
  position: absolute; top: 0; z-index: 5; pointer-events: none;
  padding: 6px 12px; border-radius: 16px; background: rgba(0,0,0,.55);
  color: #fff; font: 700 12.5px sans-serif;
}
.bar { position: absolute; top: 0; bottom: 0; width: 44px; margin-left: -22px;
  z-index: 6; touch-action: none; cursor: ew-resize; }
.bar i { position: absolute; left: 21px; top: 0; bottom: 0; width: 2px; background: #fff;
  box-shadow: 0 0 6px rgba(0,0,0,.5); }
.bar b { position: absolute; left: 2px; top: 50%; margin-top: -20px; width: 40px; height: 40px;
  border-radius: 50%; background: #fff; box-shadow: 0 2px 10px rgba(0,0,0,.5);
  color: #17606a; font: 800 15px sans-serif; text-align: center; line-height: 38px; }
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

    // --- Tarihî / günümüz ayırıcı
    let f = 0.5;
    function apply() {
      if (!od) return;
      od.style.clipPath = 'inset(0 ' + ((1 - f) * 100) + '% 0 0)';
      bar.style.left = (f * 100) + '%';
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
    let bar = null;
    if (od) {
      const lo = document.createElement('div');
      lo.className = 'lbl'; lo.textContent = CFG.oldLabel; lo.style.left = '14px'; lo.style.bottom = CFG.botPad + 'px';
      const ln = document.createElement('div');
      ln.className = 'lbl'; ln.textContent = CFG.newLabel; ln.style.right = '14px'; ln.style.bottom = CFG.botPad + 'px';
      bar = document.createElement('div');
      bar.className = 'bar';
      bar.innerHTML = '<i></i><b>↔</b>';
      document.body.append(lo, ln, bar);
      let dragging = false;
      bar.addEventListener('pointerdown', function (e) { dragging = true; bar.setPointerCapture(e.pointerId); });
      bar.addEventListener('pointerup', function () { dragging = false; });
      bar.addEventListener('pointercancel', function () { dragging = false; });
      bar.addEventListener('pointermove', function (e) {
        if (!dragging) return;
        f = Math.min(0.94, Math.max(0.06, e.clientX / window.innerWidth));
        apply();
      });
      apply();
    }

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
      if (e.target.closest && (e.target.closest('.bar') || e.target.closest('.hs'))) return;
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
