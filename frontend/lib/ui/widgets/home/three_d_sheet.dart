import '../common/action_card.dart';
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
                    child: ActionCard(
                      leading: AppNetworkImage(
                        imageUrl: p.imageAfterUrl,
                        width: 56,
                        height: 56,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: p.nameFor(en),
                      padding: const EdgeInsets.all(10),
                      round: 26,
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
