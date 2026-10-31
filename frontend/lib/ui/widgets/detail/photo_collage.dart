import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../common/app_network_image.dart';

/// Eski fotoğraflar için kolaj: solda büyük, sağda 2x2 küçük kare; 5'ten fazlaysa "+N".
/// Dokununca tam ekran, kaydırmalı ve yakınlaştırılabilir görüntüleyici açılır.
class PhotoCollage extends StatelessWidget {
  final List<String> photos;
  final String semanticPrefix;

  const PhotoCollage({
    super.key,
    required this.photos,
    this.semanticPrefix = '',
  });

  static const double _gap = 6;
  static const _radius = Radius.circular(14);

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final shown = photos.take(5).toList();
    final extra = photos.length - shown.length;

    return AspectRatio(
      aspectRatio: shown.length == 1 ? 1.6 : 1.75,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        child: _layout(context, shown, extra),
      ),
    );
  }

  Widget _layout(BuildContext context, List<String> p, int extra) {
    Widget tile(int i, {int more = 0}) => _Tile(
      url: p[i],
      more: more,
      semantic: '$semanticPrefix ${i + 1}',
      onTap: () => _open(context, i),
    );
    final n = p.length;
    if (n == 1) return tile(0);
    if (n == 2) {
      return Row(
        children: [
          Expanded(child: tile(0)),
          const SizedBox(width: _gap),
          Expanded(child: tile(1)),
        ],
      );
    }
    final right = switch (n) {
      3 => Column(
        children: [
          Expanded(child: tile(1)),
          const SizedBox(height: _gap),
          Expanded(child: tile(2)),
        ],
      ),
      4 => Column(
        children: [
          Expanded(child: tile(1)),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: tile(2)),
                const SizedBox(width: _gap),
                Expanded(child: tile(3)),
              ],
            ),
          ),
        ],
      ),
      _ => Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: tile(1)),
                const SizedBox(width: _gap),
                Expanded(child: tile(2)),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: tile(3)),
                const SizedBox(width: _gap),
                Expanded(child: tile(4, more: extra)),
              ],
            ),
          ),
        ],
      ),
    };
    return Row(
      children: [
        Expanded(flex: 2, child: tile(0)),
        const SizedBox(width: _gap),
        Expanded(flex: 2, child: right),
      ],
    );
  }

  void _open(BuildContext context, int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) =>
            PhotoViewer(photos: photos, initialIndex: index),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String url;
  final int more;
  final String semantic;
  final VoidCallback onTap;

  const _Tile({
    required this.url,
    required this.more,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(PhotoCollage._radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(imageUrl: url, semanticLabel: semantic),
            if (more > 0)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$more',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tam ekran fotoğraf görüntüleyici: yana kaydırma, iki parmakla yakınlaştırma, sayaç.
class PhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: AppNetworkImage(
                  imageUrl: widget.photos[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
