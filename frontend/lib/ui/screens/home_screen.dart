import 'package:flutter/material.dart';
import '../../core/constants/app_cities.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/app_network_image.dart';
import '../widgets/common/city_picker_sheet.dart';
import '../widgets/common/lang_toggle.dart';
import '../widgets/common/section_title.dart';
import '../widgets/common/tulip_motif.dart';
import 'places_list_screen.dart';
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
        _featuredPlaces =
            featured.isNotEmpty ? featured.take(6).toList() : all.take(6).toList();

        final byDistance = [...all]..sort((a, b) =>
            (a.distanceMeters ?? double.infinity)
                .compareTo(b.distanceMeters ?? double.infinity));
        _nearbyPlaces = byDistance.take(6).toList();
        _isLoading = false;
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
      MaterialPageRoute(
        builder: (_) => SliderScreen(place: place),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternBackground(child: Scaffold(
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
          const SizedBox(height: 14),
          _buildHorizontalList(_nearbyPlaces, large: false),
          const SizedBox(height: 28),
        ],
      ),
    ));
  }

  // ---------- Hero ----------

  Widget _buildHero() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 0),
      decoration: const BoxDecoration(color: AppColors.heroPetrol),
      child: Stack(
        children: [
          // Dekoratif lale (silik) — hero'ya doku verir
          Positioned(
            right: -24,
            bottom: 36,
            child: Opacity(
              opacity: 0.12,
              child: const TulipMotif(height: 220),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vakıf Yolu',
                    style: TextStyle(
                      fontFamily: AppTheme.headingFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const LangToggle(onDark: true),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                context.t('hero_title'),
                style: const TextStyle(
                  fontFamily: AppTheme.headingFont,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
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
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              // Arama çubuğu hero'dan krem alana taşmasın diye alt boşluk
              const SizedBox(height: 28),
            ],
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
          _quickAction(context.t('qa_nearby'), Icons.near_me_outlined,
              widget.onNearbyTap ?? widget.onExploreMapTap),
          _quickAction(context.t('qa_create_route'), Icons.alt_route_rounded, widget.onCreateRouteTap),
          _quickAction(context.t('qa_scan_qr'), Icons.qr_code_scanner_rounded, widget.onQrTap,
              highlight: true),
          _quickAction(context.t('qa_cities'), Icons.location_city_rounded,
              () => showCityPickerSheet(context)),
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, VoidCallback? onTap,
      {bool highlight = false}) {
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
                color: highlight ? AppColors.ciniBordeaux : AppColors.primaryTeal,
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

  Widget _buildHorizontalList(List<HeritagePlace> places, {required bool large}) {
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
          child: Text(context.t('no_places'),
              style: const TextStyle(color: AppColors.textMuted)),
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
          showBadge: large,
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
  final bool showBadge;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.city,
    required this.width,
    required this.showBadge,
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
              AppNetworkImage(imageUrl: place.imageAfterUrl),
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
              if (showBadge)
                const Positioned(top: 0, right: 0, child: TulipBadge()),
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
                      '${place.category.labelFor(context.isEn)} · $city',
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
