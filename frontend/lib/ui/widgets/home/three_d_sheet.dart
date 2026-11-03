import '../common/app_card.dart';
import '../common/pattern_background.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';
import '../../screens/slider_screen.dart';
import '../common/app_network_image.dart';
import '../common/sheet_handle.dart';

/// 3B modeli olan eserlerin listesi; seçilen eser 3B görünümde açılır.
Future<void> show3dPlacesSheet(
  BuildContext context,
  List<HeritagePlace> places,
) {
  final list = places.where((p) => p.has3dModel).toList();
  return showModalBottomSheet<void>(
    context: context,
    constraints: kSheetConstraints,
    clipBehavior: Clip.antiAlias,
    backgroundColor: AppColors.bgCanvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheet) {
      final en = sheet.isEn;
      return PatternBackground(
        lineOpacity: 0.07,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                Text(sheet.t('qa_3d'), style: AppTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  sheet.t('three_d_hint'),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                for (final p in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      shape: appCardBorder(round: 22),
                      child: InkWell(
                        customBorder: appCardBorder(round: 22),
                        onTap: () {
                          Navigator.pop(sheet);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SliderScreen(place: p, start3d: true),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: ShapeDecoration(
                            shape: appCardBorder(round: 22),
                          ),
                          child: Row(
                            children: [
                              AppNetworkImage(
                                imageUrl: p.imageAfterUrl,
                                width: 64,
                                height: 64,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  p.nameFor(en),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
