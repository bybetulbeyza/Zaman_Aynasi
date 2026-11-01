import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/l10n/app_lang.dart';

/// Eserin 3B modeli: döndür, yakınlaştır, AR'da aç. Tarihî / Günümüz arasında geçiş yapılır.
class Model3DView extends StatefulWidget {
  final String newUrl;
  final String oldUrl;
  final String name;
  final double bottomInset;

  const Model3DView({
    super.key,
    required this.newUrl,
    required this.oldUrl,
    required this.name,
    this.bottomInset = 0,
  });

  @override
  State<Model3DView> createState() => _Model3DViewState();
}

class _Model3DViewState extends State<Model3DView> {
  late bool _old = widget.newUrl.isEmpty;

  bool get _both => widget.newUrl.isNotEmpty && widget.oldUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final url = _old ? widget.oldUrl : widget.newUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _old
                  ? const [Color(0xFFF1E3C8), Color(0xFFD9BE92)]
                  : const [Color(0xFFDDEBF2), Color(0xFFF3EFE6)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.bottomInset),
            child: ModelViewer(
              key: ValueKey(url),
              src: url,
              alt: widget.name,
              backgroundColor: Colors.transparent,
              cameraControls: true,
              autoRotate: true,
              autoRotateDelay: 2500,
              disableZoom: false,
              ar: true,
              arModes: const ['scene-viewer', 'quick-look', 'webxr'],
              interactionPrompt: InteractionPrompt.none,
              shadowIntensity: 1,
              exposure: 1.05,
              cameraOrbit: '35deg 70deg auto',
            ),
          ),
        ),
        if (_both)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: Center(
              child: _pill(context, [
                (
                  context.t('model_old'),
                  _old,
                  () => setState(() => _old = true),
                ),
                (
                  context.t('today_label'),
                  !_old,
                  () => setState(() => _old = false),
                ),
              ]),
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

  Widget _pill(BuildContext context, List<(String, bool, VoidCallback)> items) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, on, tap) in items)
            Semantics(
              button: true,
              selected: on,
              label: label,
              child: GestureDetector(
                onTap: tap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: on ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: on ? const Color(0xFF1B3A4B) : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
