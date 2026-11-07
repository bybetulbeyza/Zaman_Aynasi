import '../widgets/common/app_icon.dart';
import '../../core/utils/search_fold.dart';
import 'package:flutter/material.dart';
import '../widgets/common/dark_cancel.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/squircle_frame.dart';
import '../widgets/common/logo_loader.dart';
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
    final query = _searchController.text;
    setState(() {
      _filteredPlaces = _allPlaces.where((place) {
        final matchesSearch = searchMatches(query, [
          place.name,
          place.city,
          place.nameEn,
          place.shortDescription,
          place.shortDescriptionEn,
        ]);
        final matchesCat =
            _selectedCategory == null || place.category == _selectedCategory;
        return matchesSearch && matchesCat;
      }).toList();
      if (_sortAlphabetical) {
        _filteredPlaces.sort((a, b) => a.name.compareTo(b.name));
      }
      // Arama varken adı eşleşenler üstte; aynı derecedekiler mevcut sırasını korur
      if (query.trim().isNotEmpty) {
        final rank = {
          for (final p in _filteredPlaces)
            p: searchRank(query, [p.name, p.nameEn]),
        };
        final order = {
          for (var i = 0; i < _filteredPlaces.length; i++)
            _filteredPlaces[i]: i,
        };
        _filteredPlaces.sort((a, b) {
          final r = rank[a]!.compareTo(rank[b]!);
          return r != 0 ? r : order[a]!.compareTo(order[b]!);
        });
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
                    if (canPop) const AppBackButton(),
                    const SizedBox(width: 8),
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
                    ? const Center(child: const LogoLoader())
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
                        separatorBuilder: (_, __) => const SizedBox(height: 52),
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
        border: Border.all(color: bordeauxOf(context), width: 1.3),
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
    final style = CategoryStyle.of(place.category);
    final date = place.constructionDate.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _openPlace(place),
          // Sabit yükseklik geniş ekranda fotoğrafı çok kırpıyordu; oranla büyür (telefonda ~225, tablette ~400)
          child: AspectRatio(
            aspectRatio: 1.7,
            child: SquircleFrame(
              radius: 40,
              child: DarkCancel(
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
        ),
        const SizedBox(height: 8),
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
                    style: AppTheme.titleLarge.copyWith(fontSize: 23),
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
