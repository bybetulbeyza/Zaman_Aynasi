import 'package:flutter/material.dart';
import '../../../core/constants/category_style.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_icon.dart';

/// Kategori renginde, içinde kategori ikonu olan damla pin. Rota modunda sıra rozeti gösterir.
class CategoryPin extends StatelessWidget {
  static const double width = 46;
  static const double height = 58;

  final PlaceCategory category;
  final bool selected;
  final int? order;

  const CategoryPin({
    super.key,
    required this.category,
    this.selected = false,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category);
    final scale = selected ? 1.18 : 1.0;
    return AnimatedScale(
      scale: scale,
      alignment: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 160),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            CustomPaint(
              size: const Size(width, height),
              painter: _PinPainter(style.color, selected),
            ),
            Positioned(
              top: 7,
              child: AppIcon(style.icon, size: 28, color: Colors.white),
            ),
            if (order != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: style.color, width: 1.6),
                  ),
                  child: Text(
                    '$order',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: style.color,
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

class _PinPainter extends CustomPainter {
  final Color color;
  final bool selected;
  _PinPainter(this.color, this.selected);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = w / 2;
    final path = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.12, h * 0.66, 0, h * 0.5, 0, r)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r), clockwise: true)
      ..cubicTo(w, h * 0.5, w * 0.88, h * 0.66, w / 2, h)
      ..close();
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.5),
      selected ? 6 : 3,
      true,
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFFFBF6EA),
    );
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      old.color != color || old.selected != selected;
}
