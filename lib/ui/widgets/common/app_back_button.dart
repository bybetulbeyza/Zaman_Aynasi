import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import 'dark_cancel.dart';

/// Uygulamanın ortak geri düğmesi: ince bir ok yerine belirgin, yuvarlak bir düğme.
/// [onPhoto] true ise fotoğraf ya da koyu zemin üstünde okunsun diye buzlu cam görünümünde olur.
class AppBackButton extends StatelessWidget {
  final bool onPhoto;
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.onPhoto = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final button = onPhoto
        ? DarkCancel(
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.38),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        : Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.chipBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: shadowOf(context, 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 19,
              color: AppColors.textDark,
            ),
          );

    return Semantics(
      button: true,
      label: context.t('a11y_back'),
      excludeSemantics: true,
      onTap: onPressed ?? () => Navigator.maybePop(context),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed ?? () => Navigator.maybePop(context),
        child: Padding(padding: const EdgeInsets.all(3), child: button),
      ),
    );
  }
}
