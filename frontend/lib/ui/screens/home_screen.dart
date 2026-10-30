import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../widgets/common/app_network_image.dart';
import 'places_list_screen.dart';
import 'slider_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onExploreMapTap;
  final VoidCallback? onNearbyTap;

  const HomeScreen({
    super.key,
    this.onExploreMapTap,
    this.onNearbyTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HeritageRepository _repository = HeritageRepository();
  String _selectedCity = 'Bursa';

  List<HeritagePlace> _featuredPlaces = [];
  bool _isLoadingFeatured = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedPlaces();
  }

  Future<void> _loadFeaturedPlaces() async {
    try {
      final all = await _repository.getPlaces();
      if (mounted) {
        setState(() {
          // isFeatured true olanları al, yoksa ilk 4 eseri vitrine çıkar
          final featured = all.where((p) => p.isFeatured).toList();
          _featuredPlaces = featured.isNotEmpty ? featured.take(4).toList() : all.take(4).toList();
          _isLoadingFeatured = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingFeatured = false);
      }
    }
  }

  void _navigateToSlider(HeritagePlace place) {
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
  }

  @override
  Widget build(BuildContext context) {
    final spotlightPlace = _featuredPlaces.isNotEmpty ? _featuredPlaces.first : null;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primaryTeal),
                  const SizedBox(width: 4),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity,
                      isDense: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textDark),
                      items: ['Bursa', 'İstanbul', 'Edirne', 'Konya'].map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCity = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textDark),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // 1. Arama Çubuğu
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlacesListScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Eser, rota veya mimari dönem ara...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. Dörtlü Kısayol Kartları
          Row(
            children: [
              Expanded(
                child: _buildShortcutCard(
                  title: 'Yakınımda',
                  icon: Icons.near_me_outlined,
                  color: AppColors.primaryTeal,
                  onTap: widget.onNearbyTap ?? widget.onExploreMapTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildShortcutCard(
                  title: 'Rota Oluştur',
                  icon: Icons.alt_route_rounded,
                  color: AppColors.ciniBordeaux,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rota oluşturma ekranı hazırlanıyor...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildShortcutCard(
                  title: 'Şehirler',
                  icon: Icons.location_city_rounded,
                  color: AppColors.ciniCobalt,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Mevcut şehir envanteri: $_selectedCity'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildShortcutCard(
                  title: 'Eserler',
                  icon: Icons.museum_outlined,
                  color: AppColors.textDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlacesListScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Öne Çıkan Vakıf Eserleri (Dinamik 4 Kart -> Doğrudan SliderScreen)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Öne Çıkan Eserler',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlacesListScreen()),
                  );
                },
                child: const Text(
                  'Tümü →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Yatay Eser Kartları
          SizedBox(
            height: 200,
            child: _isLoadingFeatured
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : _featuredPlaces.isEmpty
                ? const Center(
              child: Text(
                'Öne çıkan eser bulunamadı.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
                : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredPlaces.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final place = _featuredPlaces[index];
                return _buildHeritageCard(
                  place: place,
                  onTap: () => _navigateToSlider(place),
                );
              },
            ),
          ),
          const SizedBox(height: 26),

          // 4. Günün Kültür Mirası (Vitrin Eseri)
          if (spotlightPlace != null) ...[
            const Text(
              'Günün Kültür Mirası',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildSpotlightCard(
              place: spotlightPlace,
              onTap: () => _navigateToSlider(spotlightPlace),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeritageCard({
    required HeritagePlace place,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  imageUrl: place.imageAfterUrl,
                  width: 220,
                  height: 114,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      place.category.label,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.shortDescription,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightCard({
    required HeritagePlace place,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
              width: 84,
              height: 84,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.chipInactiveBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${place.category.label} • Keşfe Başla',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.primaryTeal, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.shortDescription,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    maxLines: 2,
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