import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';

/// Eserin 3B modeli: döndür, yakınlaştır, AR'da aç.
/// İki model de varsa aynı sayfada üst üste biner; sürüklenen çizginin solu tarihî, sağı günümüz
/// görünür ve kamera ikisinde birlikte hareket eder. Hotspot'lar modelin yüzeyine yapışır.
class Model3DView extends StatelessWidget {
  final String newUrl;
  final String oldUrl;
  final String name;
  final List<Hotspot> hotspots;
  final ValueChanged<Hotspot> onHotspot;
  final double bottomInset;

  const Model3DView({
    super.key,
    required this.newUrl,
    required this.oldUrl,
    required this.name,
    required this.onHotspot,
    this.hotspots = const [],
    this.bottomInset = 0,
  });

  static final _num = RegExp(r'^[-+0-9.eE\s]+$');

  String _hotspotHtml() {
    final b = StringBuffer();
    var n = 0;
    for (final h in hotspots) {
      final pos = h.modelPos ?? '';
      if (!_num.hasMatch(pos)) continue;
      final normal = _num.hasMatch(h.modelNormal ?? '')
          ? h.modelNormal!
          : '0 1 0';
      n++;
      b.writeln(
        '<button class="hs" slot="hotspot-$n" data-position="$pos" '
        'data-normal="$normal" data-visibility-attribute="visible" '
        'aria-label="${htmlEscapeAttr(h.title)}" '
        'onclick="HotspotTap.postMessage(\'${h.id}\')">$n</button>',
      );
    }
    return b.toString();
  }

  static String htmlEscapeAttr(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;');

  @override
  Widget build(BuildContext context) {
    final both = newUrl.isNotEmpty && oldUrl.isNotEmpty;
    final src = newUrl.isNotEmpty ? newUrl : oldUrl;
    final cfg = jsonEncode({
      'oldSrc': both ? oldUrl : '',
      'single': both ? '' : (newUrl.isNotEmpty ? 'new' : 'old'),
      'oldLabel': context.t('model_old'),
      'newLabel': context.t('today_label'),
      'topPad': MediaQuery.of(context).padding.top + 64,
    });
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ModelViewer(
            key: ValueKey('$newUrl|$oldUrl|${hotspots.length}'),
            src: src,
            alt: name,
            backgroundColor: Colors.transparent,
            cameraControls: true,
            disableZoom: false,
            ar: true,
            arModes: const ['scene-viewer', 'quick-look', 'webxr'],
            interactionPrompt: InteractionPrompt.none,
            shadowIntensity: 1,
            exposure: 1.05,
            cameraOrbit: '35deg 70deg auto',
            minCameraOrbit: 'auto 10deg auto',
            maxCameraOrbit: 'auto 90deg auto',
            innerModelViewerHtml: _hotspotHtml(),
            relatedCss: _css,
            relatedJs: _js.replaceFirst('__CFG__', cfg),
            javascriptChannels: {
              JavascriptChannel(
                'HotspotTap',
                onMessageReceived: (m) {
                  for (final h in hotspots) {
                    if (h.id.toString() == m.message) {
                      onHotspot(h);
                      break;
                    }
                  }
                },
              ),
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset + 14,
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

  static const _js = r'''
(function () {
  const CFG = __CFG__;
  const OLD_BG = 'linear-gradient(#f1e3c8,#d9be92)';
  const NEW_BG = 'linear-gradient(#ddebf2,#f3efe6)';
  customElements.whenDefined('model-viewer').then(function () {
    const nw = document.querySelector('model-viewer');
    const fill = 'position:absolute;left:0;top:0;width:100%;height:100%;';
    nw.style.cssText = fill;
    document.body.style.position = 'relative';
    const fixed = CFG.single === 'old';
    nw.style.background = fixed ? OLD_BG : NEW_BG;
    if (!CFG.oldSrc) return;

    const od = document.createElement('model-viewer');
    for (const a of nw.attributes) {
      if (a.name !== 'src' && a.name !== 'style' && a.name !== 'ar' && a.name !== 'ar-modes') {
        od.setAttribute(a.name, a.value);
      }
    }
    od.setAttribute('src', CFG.oldSrc);
    od.innerHTML = nw.innerHTML;
    od.style.cssText = fill + 'background:' + OLD_BG + ';';
    nw.after(od);

    let f = 0.5;
    const lo = document.createElement('div');
    lo.className = 'lbl'; lo.textContent = CFG.oldLabel; lo.style.left = '14px'; lo.style.top = CFG.topPad + 'px';
    const ln = document.createElement('div');
    ln.className = 'lbl'; ln.textContent = CFG.newLabel; ln.style.right = '14px'; ln.style.top = CFG.topPad + 'px';
    const bar = document.createElement('div');
    bar.className = 'bar';
    bar.innerHTML = '<i></i><b>↔</b>';
    document.body.append(lo, ln, bar);

    function apply() {
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
    apply();

    let dragging = false;
    bar.addEventListener('pointerdown', function (e) { dragging = true; bar.setPointerCapture(e.pointerId); });
    bar.addEventListener('pointerup', function () { dragging = false; });
    bar.addEventListener('pointercancel', function () { dragging = false; });
    bar.addEventListener('pointermove', function (e) {
      if (!dragging) return;
      f = Math.min(0.94, Math.max(0.06, e.clientX / window.innerWidth));
      apply();
    });

    let active = null, until = 0;
    function mark(el) { return function (e) {
      if (e.detail && e.detail.source === 'user-interaction') { active = el; until = performance.now() + 1800; }
    }; }
    nw.addEventListener('camera-change', mark(nw));
    od.addEventListener('camera-change', mark(od));
    function copy(a, b) {
      const o = a.getCameraOrbit(), t = a.getCameraTarget();
      b.cameraOrbit = o.theta + 'rad ' + o.phi + 'rad ' + o.radius + 'm';
      b.cameraTarget = t.x + 'm ' + t.y + 'm ' + t.z + 'm';
      b.jumpCameraToGoal();
    }
    function loop(now) {
      if (active && now < until) { copy(active, active === nw ? od : nw); apply(); }
      requestAnimationFrame(loop);
    }
    requestAnimationFrame(loop);
  });
})();
''';
}
