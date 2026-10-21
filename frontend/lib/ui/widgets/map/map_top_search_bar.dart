import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MapTopSearchBar extends StatefulWidget {
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onFilterSelected;

  const MapTopSearchBar({
    super.key,
    this.onSearchChanged,
    this.onFilterSelected,
  });

  @override
  State<MapTopSearchBar> createState() => _MapTopSearchBarState();
}

class _MapTopSearchBarState extends State<MapTopSearchBar> {
  // Başlangıçta tasarımdaki gibi rota seçili gelir
  String _selectedCategory = 'Rota: Han ve Çarşı';

  final List<String> _categories = [
    'Rota: Han ve Çarşı',
    'Cami',
    'Han',
    'Hamam',
    'Medrese',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Arama Çubuğu
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppColors.borderSubtle, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            onChanged: widget.onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Eser, semt veya rota ara',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Yatay Kategori Çipleri (Filtreler)
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
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
                    // Seçiliyse Zümrüt Yeşili, değilse beyaz zemin
                    color: isSelected ? AppColors.leafGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.leafGreen
                          : AppColors.borderSubtle,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isSelected ? 0.12 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}