import 'package:flutter/material.dart';
import 'dark_cancel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import 'app_logo.dart';
import 'shimmer_box.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Ekran okuyucular için görsel açıklaması (örn. eser adı).
  final String? semanticLabel;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) {
        // Işık süzülen iskelet + silik logo; boyut belliyse logo ona göre ölçeklenir
        final side = (width != null && height != null)
            ? (width! < height! ? width! : height!) * 0.3
            : 36.0;
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ShimmerBox(),
              Center(
                child: Opacity(
                  opacity: 0.3,
                  child: AppLogo(size: side.clamp(20.0, 48.0)),
                ),
              ),
            ],
          ),
        );
      },
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: AppColors.borderSubtle,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textMuted,
          size: 22,
        ),
      ),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    imageWidget = DarkCancel(child: imageWidget);
    if (semanticLabel == null) return imageWidget;
    return Semantics(image: true, label: semanticLabel, child: imageWidget);
  }
}
