import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Uygulamanın tek bildirim stili: altta yüzen, koyu petrol, yuvarlak köşeli balon.
/// [actionLabel] verilirse sağda dokunulabilir bir düğme çıkar. Her zaman kendiliğinden kapanır
/// (SnackBarAction kullanılmaz; o, düğme varken balonu açık bırakır).
class AppToast {
  static void show(
    BuildContext context,
    String text, {
    IconData icon = Icons.check_rounded,
    String? actionLabel,
    VoidCallback? onAction,
    double bottomMargin = 12,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        padding: EdgeInsets.fromLTRB(14, 6, actionLabel == null ? 14 : 6, 6),
        backgroundColor: AppColors.heroPetrol,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: duration,
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(actionLabel),
              ),
          ],
        ),
      ),
    );
  }
}
