import '../../../core/l10n/app_lang.dart';
import 'action_card.dart';
import 'pattern_background.dart';
import 'sheet_handle.dart';
import 'package:flutter/material.dart';
import 'dark_cancel.dart';
import '../../../core/constants/app_cities.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';

/// Şehir seçim sayfası. Henüz verisi olmayan şehirler "Yakında" olarak gösterilir.
Future<void> showCityPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    constraints: kSheetConstraints,
    clipBehavior: Clip.antiAlias,
    backgroundColor: AppColors.bgCanvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => PatternBackground(
      lineOpacity: 0.07,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Text(context.t('qa_cities'), style: AppTheme.titleLarge),
              const SizedBox(height: 14),
              for (final city in AppCities.all)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ActionCard(
                    leading: ActionCard.iconBubble(
                      context,
                      Icons.location_on_outlined,
                    ),
                    title: city,
                    dimmed: !AppCities.isAvailable(city),
                    selected: AppCities.isAvailable(city),
                    round: 26,
                    trailing: AppCities.isAvailable(city)
                        ? null
                        : Text(
                            context.t('soon'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: bordeauxOf(context),
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
