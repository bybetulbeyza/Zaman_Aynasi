import 'package:flutter/material.dart';
import '../../core/constants/app_cities.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/utils/location_service.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/app_network_image.dart';
import '../widgets/common/city_picker_sheet.dart';
import '../widgets/common/lang_toggle.dart';
import '../widgets/common/section_title.dart';
import '../widgets/common/app_logo.dart';
import 'places_list_screen.dart';
import 'reels_screen.dart';
import 'slider_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onExploreMapTap;
  final VoidCallback? onNearbyTap;
  final VoidCallback? onQrTap;
  final VoidCallback? onCreateRouteTap;

  const HomeScreen({
    super.key,
    this.onExploreMapTap,
    this.onNearbyTap,
    this.onQrTap,
    this.onCreateRouteTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HeritageRepository _repository = HeritageRepository();
  static const String _city = AppCities.active;

  List<HeritagePlace> _featuredPlaces = [];
  List<HeritagePlace> _nearbyPlaces = [];
  bool _isLoading = true;
  bool _locationOff = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final all = await _repository.getPlaces();
      if (!mounted) return;
      setState(() {
        final featured = all.where((p) => p.isFeatured).toList();
        _featuredPlaces = featured.isNotEmpty
            ? featured.take(6).toList()
            : all.take(6).toList();
        _nearbyPlaces = all.take(6).toList(); // konum gelene kadar geçici
        _isLoading = false;
      });

      // Konum izni içeriği bekletmesin diye ayrıca çözülür
      final user = await LocationService.getCurrentLocation();
      if (!mounted) return;
      final sorted = LocationService.sortPlacesByDistance(
        places: all,
        userLocation: user,
      );
      setState(() {
        _nearbyPlaces = sorted.take(6).toList();
        _locationOff = LocationService.lastWasFallback;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openPlaces() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlacesListScreen()),
    );
  }

  void _openSlider(HeritagePlace place) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SliderScreen(place: place)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHero(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionTitle(
                context.t('home_featured'),
                actionLabel: context.t('all'),
                onAction: _openPlaces,
              ),
            ),
            const SizedBox(height: 14),
            _buildHorizontalList(_featuredPlaces, large: true),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionTitle(context.t('home_nearby')),
            ),
            if (_locationOff)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.t('location_off_note'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            _buildHorizontalList(_nearbyPlaces, large: false),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ---------- Hero ----------

  Widget _buildHero() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 10, 20, 24),
      // Desen hero'da silik tutulur; marka, arama ve kısayollar öne çıksın
      decoration: PatternBackground.onDarkDecoration(lineOpacity: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: LangToggle(onDark: true),
          ),
          const SizedBox(height: 14),
          // Marka bloğu: süslü dikey çizgi, ad ve slogan solda; logo sağda
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _brandOrnament(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Zaman Aynası',
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: AppTheme.brandFont,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t('hero_title').replaceAll('\n', ' '),
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        letterSpacing: 1.3,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const AppLogo(size: 84, shadow: true),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _openPlaces,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.ciniBordeaux, width: 1.3),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.textDark),
                  const SizedBox(width: 12),
                  Text(
                    context.t('search_hint'),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// İnce dikey çizginin ortasında küçük elmas süs.
  Widget _brandOrnament() {
    return SizedBox(
      width: 14,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 1,
            color: AppColors.ornamentGold.withValues(alpha: 0.75),
          ),
          Transform.rotate(
            angle: 0.7853981634,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.heroPetrol,
                border: Border.all(color: AppColors.ornamentGold, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Hızlı eylemler ----------

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickAction(
            context.t('qa_nearby'),
            Icons.near_me_outlined,
            widget.onNearbyTap ?? widget.onExploreMapTap,
          ),
          _quickAction(
            context.t('qa_create_route'),
            Icons.alt_route_rounded,
            widget.onCreateRouteTap,
          ),
          _quickAction(
            context.t('qa_stories'),
            Icons.play_circle_outline_rounded,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReelsScreen()),
            ),
            highlight: true,
          ),
          _quickAction(
            context.t('qa_cities'),
            Icons.location_city_rounded,
            () => showCityPickerSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    String label,
    IconData icon,
    VoidCallback? onTap, {
    bool highlight = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryTealLight,
                shape: BoxShape.circle,
                border: highlight
                    ? Border.all(color: AppColors.ciniBordeaux, width: 1.4)
                    : null,
              ),
              child: Icon(
                icon,
                size: 24,
                color: highlight
                    ? AppColors.ciniBordeaux
                    : AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Yatay kart listeleri ----------

  Widget _buildHorizontalList(
    List<HeritagePlace> places, {
    required bool large,
  }) {
    final height = large ? 232.0 : 168.0;
    if (_isLoading) {
      return SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );
    }
    if (places.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            context.t('no_places'),
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _PlaceCard(
          place: places[i],
          city: _city,
          width: large ? 164 : 150,
          distanceLabel: (!large && !_locationOff)
              ? LocationService.formatDistance(places[i].distanceMeters)
              : '',
          onTap: () => _openSlider(places[i]),
        ),
      ),
    );
  }
}

/// Görselin tam kapladığı, altta gradyan üzerinde isim ve "Kategori · Şehir" yazan kart.
class _PlaceCard extends StatelessWidget {
  final HeritagePlace place;
  final String city;
  final double width;
  final String distanceLabel;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.city,
    required this.width,
    this.distanceLabel = '',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(18));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
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
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1.0],
                    colors: [Colors.transparent, Color(0xCC0F2F3A)],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.nameFor(context.isEn),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 19,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${place.category.labelFor(context.isEn)} · ${distanceLabel.isNotEmpty ? distanceLabel : city}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
