import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../../core/constants/app_theme.dart';
import '../widgets/common/app_network_image.dart';
import '../widgets/common/filter_chip_pill.dart';
import '../widgets/common/tulip_motif.dart';
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
  String _selectedCategory = 'Tümü';
  bool _sortAlphabetical = false;

  final List<String> _categories = [
    'Tümü',
    'Cami',
    'Han',
    'Hamam',
    'Türbe',
    'Külliye',
  ];

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
        final matchesSearch = place.name.toLowerCase().contains(query) ||
            place.shortDescription.toLowerCase().contains(query);
        final matchesCat = _selectedCategory == 'Tümü' ||
            place.category.label.toLowerCase().trim() == _selectedCategory.toLowerCase().trim();
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
      MaterialPageRoute(
        builder: (_) => SliderScreen.fromPlace(place),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
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
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 20, color: AppColors.textDark),
                      ),
                    ),
                  const Text('Tarih Envanteri', style: AppTheme.displayLarge),
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
                children: _categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChipPill(
                      label: cat,
                      selected: _selectedCategory == cat,
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
                    "Bursa'da ${_filteredPlaces.length} eser",
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textDark),
                  ),
                  GestureDetector(
                    onTap: () {
                      _sortAlphabetical = !_sortAlphabetical;
                      _applyFilter();
                    },
                    child: Text(
                      _sortAlphabetical ? 'Sırala · A-Z' : 'Sırala',
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
                          color: AppColors.primaryTeal))
                  : _filteredPlaces.isEmpty
                      ? const Center(
                          child: Text('Eşleşen eser bulunamadı.',
                              style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          itemCount: _filteredPlaces.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 20),
                          itemBuilder: (_, i) =>
                              _buildPlaceCard(_filteredPlaces[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
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
              decoration: const InputDecoration(
                hintText: 'Eser adı veya semt ara',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: AppColors.textDark),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: AppColors.primaryTeal,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(HeritagePlace place) {
    const radius = BorderRadius.all(Radius.circular(20));
    final subtitle = [
      place.category.label,
      if (place.constructionDate.trim().isNotEmpty) place.constructionDate.trim(),
    ].join(' · ');

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
                  AppNetworkImage(imageUrl: place.imageAfterUrl),
                  const Positioned(top: 0, right: 0, child: TulipBadge()),
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
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PillButton('Keşfet', onPressed: () => _openPlace(place)),
          ],
        ),
      ],
    );
  }
}
