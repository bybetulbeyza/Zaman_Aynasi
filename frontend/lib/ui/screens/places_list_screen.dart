import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../widgets/common/app_network_image.dart';
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

  final List<String> _categories = [
    'Tümü',
    'Han & Çarşı',
    'Cami & Külliye',
    'Hamam',
    'Medrese',
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kültür Mirası Kataloğu',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Arama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 0.8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilter(),
                decoration: const InputDecoration(
                  hintText: 'Eser adı veya mimari terim ara...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                ),
              ),
            ),
          ),

          // 2. Kategori Çipleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                      _applyFilter();
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primaryTeal.withOpacity(0.15),
                    checkmarkColor: AppColors.primaryTeal,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryTeal : AppColors.borderSubtle,
                      width: 0.8,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primaryTeal : AppColors.textDark,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // 3. Eser Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : _filteredPlaces.isEmpty
                ? const Center(
              child: Text(
                'Eşleşen eser bulunamadı.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _filteredPlaces.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final place = _filteredPlaces[index];
                return _buildPlaceCard(place);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(HeritagePlace place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SliderScreen(
              title: place.name,
              beforeImageUrl: place.imageBeforeUrl,
              afterImageUrl: place.imageAfterUrl,
              description: place.shortDescription,
              hotspots: place.hotspots,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AppNetworkImage(
              imageUrl: place.imageAfterUrl,
              width: 76,
              height: 76,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.chipInactiveBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      place.category.label,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.shortDescription,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}