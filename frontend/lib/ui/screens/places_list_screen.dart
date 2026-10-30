import '../widgets/common/app_icon.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/category_style.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../../core/constants/app_theme.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/app_network_image.dart';
import '../widgets/common/filter_chip_pill.dart';
import '../widgets/common/pill_button.dart';
import 'slider_screen.dart';

class PlacesListScreen extends StatefulWidget {
  const PlacesListScreen({super.key});

  @override
  State<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends State<PlacesListScreen> {
  final HeritageRepository _repository = HeritageRepository();
  final TextEditingController _searchController = TextEditingController();

  List<HeritagePlace> _allPlaces = [];
  List<HeritagePlace> _filteredPlaces = [];
  bool _isLoading = true;
  PlaceCategory? _selectedCategory; // null = Tümü
  bool _sortAlphabetical = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    final places = await _repository.getPlaces();
    if (mounted) {
      setState(() {
        _allPlaces = places;
        _filteredPlaces = places;
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredPlaces = _allPlaces.where((place) {
        final matchesSearch =
            place.name.toLowerCase().contains(query) ||
            place.nameEn.toLowerCase().contains(query) ||
            place.shortDescription.toLowerCase().contains(query) ||
            place.shortDescriptionEn.toLowerCase().contains(query);
        final matchesCat =
            _selectedCategory == null || place.category == _selectedCategory;
        return matchesSearch && matchesCat;
      }).toList();
      if (_sortAlphabetical) {
        _filteredPlaces.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

  void _openPlace(HeritagePlace place) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SliderScreen(place: place)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    if (canPop)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    Text(context.t('inv_title'), style: AppTheme.displayLarge),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchRow(),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: AppCategories.filters.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChipPill(
                        label: cat == null
                            ? context.t('all_filter')
                            : cat.labelFor(context.isEn),
                        selected: _selectedCategory == cat,
                        icon: cat == null ? null : CategoryStyle.of(cat).icon,
                        accent: cat == null
                            ? null
                            : CategoryStyle.of(cat).color,
                        onTap: () {
                          _selectedCategory = cat;
                          _applyFilter();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context
                          .t('inv_count')
                          .replaceAll('{n}', '${_filteredPlaces.length}'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _sortAlphabetical = !_sortAlphabetical;
                        _applyFilter();
                      },
                      child: Text(
                        _sortAlphabetical
                            ? '${context.t('sort')} · A-Z'
                            : context.t('sort'),
                        style: const TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      )
                    : _filteredPlaces.isEmpty
                    ? Center(
                        child: Text(
                          context.t('no_match'),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: _filteredPlaces.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (_, i) =>
                            _buildPlaceCard(_filteredPlaces[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.ciniBordeaux, width: 1.3),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilter(),
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: context.t('search_hint'),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
          border: InputBorder.none,
          icon: const AppIcon('search', color: AppColors.textDark, size: 24),
        ),
      ),
    );
  }

  Widget _buildPlaceCard(HeritagePlace place) {
    const radius = BorderRadius.all(Radius.circular(20));
    final style = CategoryStyle.of(place.category);
    final date = place.constructionDate.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openPlace(place),
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: AppColors.ciniBordeaux.withValues(alpha: 0.45),
                width: 1.1,
              ),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl: place.imageAfterUrl,
                    semanticLabel: place.nameFor(context.isEn),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.nameFor(context.isEn),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
                        decoration: BoxDecoration(
                          color: style.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(style.icon, size: 18, color: style.color),
                            const SizedBox(width: 5),
                            Text(
                              place.category.labelFor(context.isEn),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: style.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PillButton(
              context.t('explore'),
              onPressed: () => _openPlace(place),
            ),
          ],
        ),
      ],
    );
  }
}
