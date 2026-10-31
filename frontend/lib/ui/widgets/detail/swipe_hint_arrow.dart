import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Bilgi kartının yukarı çekilebildiğini söyleyen, hafifçe zıplayan çift ok.
class SwipeHintArrow extends StatefulWidget {
  final VoidCallback? onTap;
  const SwipeHintArrow({super.key, this.onTap});

  @override
  State<SwipeHintArrow> createState() => _SwipeHintArrowState();
}

class _SwipeHintArrowState extends State<SwipeHintArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(_c.value);
                return Transform.translate(
                  offset: Offset(0, -6 * t),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.35 + 0.4 * t,
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 34,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, 9),
                        child: Opacity(
                          opacity: 0.75 - 0.4 * t,
                          child: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 34,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
