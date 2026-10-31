import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/models/heritage_place.dart';
import '../widgets/slider/split_slider_widget.dart';

/// Yatay tam ekran karşılaştırma: fotoğraf kırpılmadan tüm genişlikte, slider ve hotspot'larla.
class FullscreenSliderScreen extends StatefulWidget {
  final HeritagePlace place;

  const FullscreenSliderScreen({super.key, required this.place});

  @override
  State<FullscreenSliderScreen> createState() => _FullscreenSliderScreenState();
}

class _FullscreenSliderScreenState extends State<FullscreenSliderScreen> {
  Hotspot? _selected;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = context.isEn;
    final place = widget.place;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: SplitSliderWidget(
              beforeImageUrl: place.imageBeforeUrl,
              afterImageUrl: place.imageAfterUrl,
              afterLabel: context.t('period_label'),
              beforeLabel: context.t('today_label'),
              hotspots: place.hotspots,
              onHotspotSelected: (h) => setState(() => _selected = h),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.fullscreen_exit_rounded,
                  color: Colors.white,
                  size: 30,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          if (_selected != null)
            Positioned(
              left: 20,
              bottom: 16,
              width: 420,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selected!.titleFor(en),
                              style: const TextStyle(
                                fontFamily: AppTheme.headingFont,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selected = null),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selected!.descriptionFor(en),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
