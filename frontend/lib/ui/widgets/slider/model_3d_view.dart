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
  final TourController? tourController;

  /// Koyu modda sahne zemini koyu olur (modellerin kendi renkleri değişmez).
  final bool darkBackground;

  const Model3DView({
    super.key,
    required this.newUrl,
    required this.oldUrl,
    required this.name,
    required this.onHotspot,
    this.selected,
    this.hotspots = const [],
    this.bottomInset = 0,
    this.tourController,
    this.darkBackground = false,
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
  double _f =
      0.5; // bölücü konumu; çizgi ve geçiş web sayfasında çizilir, burada yalnızca rozetler için

  int _syncedStops = -1;
  bool _syncedTouring = false;
  int _syncedStep = 0;

  void _syncTour() {
    final c = widget.tourController;
    if (c == null) return;
    final n = _valid.length;
    if (_syncedStops == n &&
        _syncedTouring == _touring &&
        _syncedStep == _tourIdx) {
      return;
    }
    _syncedStops = n;
    _syncedTouring = _touring;
    _syncedStep = _tourIdx;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      c.sync(
        n,
        _touring,
        () => _touring ? _stopTour() : _startTour(),
        step: _tourIdx,
        owner: this,
      );
    });
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
      // Kapatınca kamera yerinde kalır; kullanıcı o bölümü incelemeye devam edebilir
      if (_touring) _stopTour(notify: false);
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
        _js('window.zaReset()'); // tur bitince genel görünüme dön
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
    final tc = widget.tourController;
    if (tc != null) tc.release(this);
    _tourTimer?.cancel();
    super.dispose();
  }

  /// Verilen hotspot'lar için model-viewer düğmeleri. [ar] true ise varsayılan AR düğmesi gizlenir.
  String _hotspotHtml(Iterable<Hotspot> list, {bool ar = false}) {
    final b = StringBuffer();
    if (ar)
      b.writeln('<button slot="ar-button" style="display:none"></button>');
    for (final h in list) {
      final normal = Model3DView._num.hasMatch(h.modelNormal ?? '')
          ? h.modelNormal!
          : '0 1 0';
      b.writeln(
        '<button class="hs" slot="hotspot-${h.id}" data-position="${h.modelPos}" '
        'data-normal="$normal" data-visibility-attribute="visible" '
        'aria-label="${Model3DView.htmlEscapeAttr(h.title)}" '
        'onclick="HotspotTap.postMessage(\'${h.id}\')"></button>',
      );
    }
    return b.toString();
  }

  static bool _isOldSide(Hotspot h) =>
      h.targetSide.trim().toLowerCase() == 'after';

  @override
  Widget build(BuildContext context) {
    final newUrl = widget.newUrl;
    final oldUrl = widget.oldUrl;
    final both = newUrl.isNotEmpty && oldUrl.isNotEmpty;
    final src = newUrl.isNotEmpty ? newUrl : oldUrl;
    // İki model varken her model kendi hotspot'larını taşır: 'after' (tarihî) eski modelde,
    // 'before' (günümüz) yeni modelde. Tek model varsa hepsi onda görünür.
    final forOld = both ? _valid.where(_isOldSide).toList() : <Hotspot>[];
    final forNew = both ? _valid.where((h) => !_isOldSide(h)).toList() : _valid;
    final cfg = jsonEncode({
      'oldSrc': both ? oldUrl : '',
      'single': both ? '' : (newUrl.isNotEmpty ? 'new' : 'old'),
      'dark': widget.darkBackground,
      'oldHtml': _hotspotHtml(forOld),
      'hs': [
        for (final h in _valid)
          {
            'id': h.id.toString(),
            'side': _isOldSide(h) ? 'after' : 'before',
            'p': Model3DView._nums(h.modelPos, [0, 10, 0]),
            'n': Model3DView._nums(h.modelNormal, [0, 0, -1]),
          },
      ],
    });
    final top = MediaQuery.of(context).padding.top + 12;
    _syncTour();
    return LayoutBuilder(
      builder: (context, box) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: widget.bottomInset),
              child: ModelViewer(
                key: ValueKey(
                  '$newUrl|$oldUrl|${widget.hotspots.length}|${widget.darkBackground}',
                ),
                src: src,
                alt: widget.name,
                backgroundColor: Colors.transparent,
                cameraControls: true,
                disableZoom: false,
                ar: false,
                interactionPrompt: InteractionPrompt.none,
                shadowIntensity: 0,
                exposure: 1.05,
                cameraOrbit: '35deg 70deg auto',
                fieldOfView: '45deg',
                innerModelViewerHtml: _hotspotHtml(forNew, ar: true),
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
                      if (msg == 'haptic') {
                        HapticFeedback.mediumImpact();
                      } else if (msg.startsWith('f:')) {
                        final v = double.tryParse(msg.substring(2));
                        if (v != null && mounted) setState(() => _f = v);
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

            // Yakınlaşınca: oran ve sıfırlama
            Positioned(
              right: 16,
              top: top + 46,
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
  pointer-events: auto; position: relative; width: 22px; height: 22px; border-radius: 50%; padding: 0;
  border: 0; background: #fff; cursor: pointer;
  box-shadow: 0 2px 6px rgba(0,0,0,.3);
}
.hs::before {
  content: ''; position: absolute; left: -6px; top: -6px; width: 34px; height: 34px;
  border-radius: 50%; background: rgba(255,255,255,.35); pointer-events: none;
  transform: scale(1.12); opacity: .75;
}
.hs::after {
  content: ''; position: absolute; left: 6px; top: 6px; width: 10px; height: 10px;
  border-radius: 50%; background: #0E807A;
}
#gline { position: absolute; top: 0; bottom: 0; width: 2.5px; margin-left: -1.25px; z-index: 6;
  pointer-events: none;
  background: linear-gradient(to bottom, rgba(255,255,255,0), rgba(255,255,255,.95) 20%, rgba(255,255,255,.95) 80%, rgba(255,255,255,0));
  box-shadow: 0 0 10px rgba(255,255,255,.45); }
#gknob { position: absolute; top: 50%; width: 56px; height: 140px; margin: -70px 0 0 -28px; z-index: 7;
  touch-action: none; display: flex; align-items: center; justify-content: center; }
#gknob .ring { position: absolute; width: 56px; height: 56px; border-radius: 50%;
  border: 1.4px solid rgba(255,255,255,.3); transform: scale(1.14); pointer-events: none; }
#gknob .dot { width: 48px; height: 48px; border-radius: 50%; box-sizing: border-box;
  background: linear-gradient(135deg, rgba(255,255,255,.55), rgba(255,255,255,.26));
  border: 1.3px solid rgba(255,255,255,.75); box-shadow: 0 4px 14px rgba(0,0,0,.22);
  display: flex; align-items: center; justify-content: center; color: #fff;
  transition: transform .16s ease-out; pointer-events: none; }
#gknob.on .dot { transform: scale(1.14); }
@keyframes kring { from { transform: scale(1); opacity: 1; } to { transform: scale(1.28); opacity: .2; } }
@keyframes hshalo { from { transform: scale(1); opacity: 1; } to { transform: scale(1.25); opacity: .43; } }
''';

  static const _js_ = r'''
(function () {
  const CFG = __CFG__;
  const OLD_BG = CFG.dark ? 'linear-gradient(#3a3025,#1d1710)' : 'linear-gradient(#f1e3c8,#d9be92)';
  const NEW_BG = CFG.dark ? 'linear-gradient(#1b3b46,#0a1b21)' : 'linear-gradient(#ddebf2,#f3efe6)';
  const DEG = Math.PI / 180;
  customElements.whenDefined('model-viewer').then(function () {
    const nw = document.querySelector('model-viewer');
    const fill = 'position:absolute;left:0;top:0;width:100%;height:100%;';
    nw.style.cssText = fill;
    document.body.style.position = 'relative';
    nw.style.background = CFG.single === 'old' ? OLD_BG : NEW_BG;
    let od = null, oldWrap = null;
    if (CFG.oldSrc) {
      od = document.createElement('model-viewer');
      for (const a of nw.attributes) {
        if (a.name !== 'src' && a.name !== 'style' && a.name !== 'ar' && a.name !== 'ar-modes') {
          od.setAttribute(a.name, a.value);
        }
      }
      od.setAttribute('src', CFG.oldSrc);
      od.removeAttribute('camera-controls');
      od.removeAttribute('interpolation-decay');
      od.innerHTML = CFG.oldHtml || '';
      od.style.cssText = 'position:absolute;left:0;top:0;height:100%;background:' + OLD_BG + ';pointer-events:none;';
      oldWrap = document.createElement('div');
      oldWrap.style.cssText = 'position:absolute;left:0;top:0;height:100%;width:50%;overflow:hidden;will-change:width;pointer-events:none;';
      oldWrap.appendChild(od);
      nw.after(oldWrap);
      const fit = function () { od.style.width = window.innerWidth + 'px'; };
      fit(); window.addEventListener('resize', fit);
    }
    const els = od ? [nw, od] : [nw];
    nw.setAttribute('interpolation-decay', '90');

    // --- Kamera sınırları: zemin altına inilmez, çok uzaklaşılmaz
    let base = 60, home = null, homeT = null, limXZ = 20, limY = 20, halfX = 40, halfZ = 40;
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
      syncSize();
      limits();
      // Kaydırma sınırları modelin boyutuna göre (büyük yapılarda hotspot'a gidilebilsin)
      const dm = nw.getDimensions();
      halfX = dm.x / 2; halfZ = dm.z / 2;
      limXZ = Math.max(20, 0.5 * Math.max(dm.x, dm.z));
      limY = Math.max(20, dm.y * 1.2);
      const o = nw.getCameraOrbit(), t = nw.getCameraTarget();
      home = { th: o.theta, ph: Math.min(o.phi, 84 * DEG), r: o.radius };
      homeT = { x: t.x, y: t.y, z: t.z };
    });
    function clampTarget(e) {
      const t = e.getCameraTarget();
      const x = Math.min(limXZ, Math.max(-limXZ, t.x)), y = Math.min(limY, Math.max(2, t.y)), z = Math.min(limXZ, Math.max(-limXZ, t.z));
      if (x !== t.x || y !== t.y || z !== t.z) {
        e.cameraTarget = x + 'm ' + y + 'm ' + z + 'm';
        e.jumpCameraToGoal();
      }
    }

    // --- Tarihî / günümüz ayırıcı: çizgi, tutamaç ve geçiş aynı sayfada çizilir (gecikme olmaz)
    let f = 0.5, fMsgT = 0, fAnim = 0;
    let gline = null, gknob = null;
    function apply() {
      if (!od) return;
      oldWrap.style.width = (f * 100) + '%';
      gline.style.left = (f * 100) + '%';
      gknob.style.left = (f * 100) + '%';
      if (!fMsgT) fMsgT = setTimeout(function () { fMsgT = 0; ZoomCh.postMessage('f:' + f); }, 120);
    }
    // Ayırıcıyı yumuşakça verilen konuma kaydırır (hotspot'un bulunduğu model görünsün diye)
    function slideTo(to) {
      cancelAnimationFrame(fAnim);
      const from = f, t0 = performance.now();
      (function step(now) {
        const p = Math.min(1, (now - t0) / 550);
        const e = p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;
        f = from + (to - from) * e;
        apply();
        if (p < 1) fAnim = requestAnimationFrame(step);
      })(t0);
    }
    let userTouched = false;
    if (od) {
      gline = document.createElement('div'); gline.id = 'gline';
      gknob = document.createElement('div'); gknob.id = 'gknob';
      gknob.innerHTML = '<div class="ring"></div><div class="dot"><svg width="20" height="20" viewBox="0 0 24 24" fill="#fff"><path d="M15.41 7.41 14 6l-6 6 6 6 1.41-1.41L10.83 12z"/></svg><svg width="20" height="20" viewBox="0 0 24 24" fill="#fff"><path d="M10 6 8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z"/></svg></div>';
      document.body.append(gline, gknob);
      let dragging = false;
      gknob.addEventListener('pointerdown', function (e) {
        dragging = true; userTouched = true; gknob.classList.add('on');
        gknob.setPointerCapture(e.pointerId); ZoomCh.postMessage('haptic');
      });
      const end = function () { dragging = false; gknob.classList.remove('on'); };
      gknob.addEventListener('pointerup', end);
      gknob.addEventListener('pointercancel', end);
      gknob.addEventListener('pointermove', function (e) {
        if (!dragging) return;
        f = Math.min(1, Math.max(0, e.clientX / window.innerWidth));
        apply();
      });
      document.addEventListener('pointerdown', function () { userTouched = true; }, true);
      apply();
      // Açılışta çizgi kendiliğinden iki yana gider (fotoğraf slider'ıyla aynı eğri)
      const seg = [[0.5, 0.18, 0.35], [0.18, 0.82, 0.45], [0.82, 0.5, 0.20]];
      const ease = function (t) { return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2; };
      const DUR = 2200;
      let t0 = 0;
      function intro(now) {
        if (userTouched) return;
        if (!t0) t0 = now;
        const p = Math.min(1, (now - t0) / DUR);
        let acc = 0, v = 0.5;
        for (const sgm of seg) {
          if (p <= acc + sgm[2] || sgm === seg[2]) { v = sgm[0] + (sgm[1] - sgm[0]) * ease(Math.min(1, (p - acc) / sgm[2])); break; }
          acc += sgm[2];
        }
        f = v; apply();
        if (p < 1) requestAnimationFrame(intro);
      }
      let loaded = 0;
      function go() { if (++loaded === 2) setTimeout(function () { requestAnimationFrame(intro); }, 500); }
      nw.addEventListener('load', go); od.addEventListener('load', go);
    }
    window.zaAR = function () { try { nw.activateAR(); } catch (e) {} };
    if (nw.canActivateAR) ZoomCh.postMessage('ar');
    nw.addEventListener('ar-status', function () { if (nw.canActivateAR) ZoomCh.postMessage('ar'); });
    nw.addEventListener('load', function () { if (nw.canActivateAR) ZoomCh.postMessage('ar'); });

    // --- Tek ana kamera: tüm dokunmalar yeni modele (nw) gider, eski model (od) her karede onu birebir kopyalar
    let lastZ = 0;
    function syncSize() {
      if (!od) return;
      const r = nw.getBoundingClientRect();
      od.style.width = r.width + 'px';
      od.style.height = r.height + 'px';
    }
    if (od && window.ResizeObserver) new ResizeObserver(syncSize).observe(nw);
    function copy() {
      if (!od) return;
      const o = nw.getCameraOrbit(), t = nw.getCameraTarget();
      od.cameraOrbit = o.theta + 'rad ' + o.phi + 'rad ' + o.radius + 'm';
      od.cameraTarget = t.x + 'm ' + t.y + 'm ' + t.z + 'm';
      od.fieldOfView = nw.getFieldOfView() + 'deg';
      od.jumpCameraToGoal();
    }
    nw.addEventListener('camera-change', function () {
      clampTarget(nw);
      copy();
      const now = performance.now();
      if (now - lastZ > 120) {
        lastZ = now;
        const r = nw.getCameraOrbit().radius;
        if (r > 0 && home) ZoomCh.postMessage(String(Math.round(home.r / r * 10) / 10));
      }
    });
    // Sol (eski) tarafın altında kalan yeni-model hotspot'ları dokunuşu yutmasın
    // (kare başına değil, kısa aralıklarla güncellenir)
    const nwHs = Array.prototype.slice.call(nw.querySelectorAll('.hs'));
    setInterval(function () {
      if (!od) return;
      const edge = f * window.innerWidth;
      nwHs.forEach(function (b) {
        const r = b.getBoundingClientRect();
        b.style.pointerEvents = (r.left + r.width / 2 > edge) ? 'auto' : 'none';
      });
    }, 160);

    // --- Uçuş: ana kameraya verilir, eski model onu izler
    function fly(th, ph, r, tx, ty, tz) {
      nw.cameraOrbit = th + 'rad ' + ph + 'rad ' + r + 'm';
      nw.cameraTarget = tx + 'm ' + ty + 'm ' + tz + 'm';
      setTimeout(apply, 120); setTimeout(apply, 600); setTimeout(apply, 1400);
    }
    window.zaReset = function () {
      if (!home) return;
      if (od) { userTouched = true; slideTo(0.5); }
      fly(home.th, home.ph, home.r, homeT.x, homeT.y, homeT.z);
    };
    window.zaFocus = function (id) {
      let h = null;
      for (const x of CFG.hs) if (x.id === id) h = x;
      if (!h || !home) return;
      // Hotspot hangi dönemin modelindeyse ayırıcı o tarafı açar
      if (od) { userTouched = true; slideTo(h.side === 'after' ? 0.92 : 0.08); }
      const n = h.n, th = Math.atan2(n[0], n[2]);
      // Avlunun içindeki noktalara yüksekten bakılır; böylece dış duvarlar ve kapı görüşü kapatmaz
      const inner = Math.abs(h.p[0]) < 0.62 * halfX && Math.abs(h.p[2]) < 0.62 * halfZ;
      if (inner) {
        fly(th, 46 * DEG, Math.max(10, home.r * 0.24), h.p[0], Math.max(2, h.p[1]), h.p[2]);
        return;
      }
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
