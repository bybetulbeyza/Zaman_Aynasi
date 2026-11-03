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
              const Text('Şehirler', style: AppTheme.titleLarge),
              const SizedBox(height: 14),
              for (final city in AppCities.all)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppCities.isAvailable(city)
                          ? AppColors.primaryTeal
                          : AppColors.chipBorder,
                      width: AppCities.isAvailable(city) ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppCities.isAvailable(city)
                            ? AppColors.primaryTeal
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        city,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppCities.isAvailable(city)
                              ? AppColors.textDark
                              : AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      if (AppCities.isAvailable(city))
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryTeal,
                        )
                      else
                        Text(
                          'Yakında',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: bordeauxOf(context),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
