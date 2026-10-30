import 'package:flutter/material.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../data/models/heritage_place.dart';

class MapTopSearchBar extends StatefulWidget {
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<PlaceCategory?>? onFilterSelected;

  const MapTopSearchBar({
    super.key,
    this.onSearchChanged,
    this.onFilterSelected,
  });

  @override
  State<MapTopSearchBar> createState() => _MapTopSearchBarState();
}

class _MapTopSearchBarState extends State<MapTopSearchBar> {
  PlaceCategory? _selectedCategory; // null = Tümü

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Arama Çubuğu ve Yeşil Filtre Butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.inputBorderBordeaux,
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: widget.onSearchChanged,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: context.t('map_search_hint'),
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. Yatay Kategori Çipleri (Filtreler)
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: AppCategories.filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = AppCategories.filters[index];
                final isSelected = cat == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                    widget.onFilterSelected?.call(cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryTeal
                          : AppColors.chipInactiveBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryTeal
                            : AppColors.chipBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(isSelected ? 0.12 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      cat == null ? context.t('all_filter') : cat.labelFor(context.isEn),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontSize: 13,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}