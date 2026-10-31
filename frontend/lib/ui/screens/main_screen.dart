import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/state/active_route.dart';
import '../widgets/common/app_icon.dart';
import '../../data/models/heritage_place.dart';
import 'historic_routes_screen.dart';
import 'slider_screen.dart';
import '../../core/utils/geofence_service.dart';
import '../../data/repositories/heritage_repository.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'qr_scanner_screen.dart';
import 'routes_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Varsayılan olarak Ana Sayfa ile başlar
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  final GeofenceService _geofence = GeofenceService();

  @override
  void initState() {
    super.initState();
    _startGeofence();
  }

  @override
  void dispose() {
    _geofence.stop();
    super.dispose();
  }

  Future<void> _startGeofence() async {
    final places = await HeritageRepository().getPlaces();
    if (!mounted || places.isEmpty) return;
    await _geofence.start(places, (place) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Row(
            children: [
              const Icon(Icons.place_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context
                      .t('geo_nearby')
                      .replaceAll('{name}', place.nameFor(context.isEn)),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: context.t('geo_open'),
            textColor: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SliderScreen(place: place)),
            ),
          ),
        ),
      );
    });
  }

  /// Haritaya geçip verilen rotayı çizer.
  void _showRouteOnMap(List<HeritagePlace> places, {int focusIndex = 0}) {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapKey.currentState?.loadCustomRoute(places, focusIndex: focusIndex);
    });
  }

  /// Rota oluşturma formunu açar; rota hazır olunca forma geri dönmeden haritaya geçer.
  void _openRouteBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutesScreen(
          onRouteCreated: (places) {
            Navigator.pop(context); // formu kapat
            _showRouteOnMap(places);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onQrTap: () => setState(() => _currentIndex = 2),
        onCreateRouteTap: _openRouteBuilder,
        onExploreMapTap: () {
          setState(() => _currentIndex = 1);
        },
        onNearbyTap: () {
          setState(() => _currentIndex = 1);
          // Harita sekmesine geçildiğinde çerçeve çizildikten sonra yakın rotayı tetikler
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapKey.currentState?.applyNearbyRoute();
          });
        },
      ),
      MapScreen(key: _mapKey),
      const QRScannerScreen(),
      HistoricRoutesScreen(
        onRouteStarted: _showRouteOnMap,
        onShowStop: (stops, i) => _showRouteOnMap(stops, focusIndex: i),
        onCreateRoute: _openRouteBuilder,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  static const double _qrSize = 62;
  static const double _barHeight = 66;

  Widget _buildBottomBar() {
    return Container(
      color: AppColors.cardBg,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight + _qrSize / 2 - 8,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Bordo çizgili bar zemini
              Positioned(
                left: 0,
                right: 0,
                top: _qrSize / 2 - 8,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.cardBg,
                    border: Border(
                      top: BorderSide(color: AppColors.dividerLine, width: 1.2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight - 4,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildNavItem(
                        icon: 'home',
                        label: context.t('nav_home'),
                        index: 0,
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        icon: 'map',
                        label: context.t('nav_map'),
                        index: 1,
                      ),
                    ),
                    Expanded(child: _buildQrLabel()),
                    Expanded(
                      child: _buildNavItem(
                        icon: 'routes',
                        label: context.t('nav_routes'),
                        index: 3,
                        showRouteBadge: true,
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        icon: 'profile',
                        label: context.t('nav_profile'),
                        index: 4,
                      ),
                    ),
                  ],
                ),
              ),
              // Çubuğun üstüne taşan QR butonu (krem halkalı)
              Positioned(top: 0, child: _buildQrButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String label,
    required int index,
    bool showRouteBadge = false,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primaryTeal : AppColors.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          showRouteBadge
              ? ListenableBuilder(
                  listenable: ActiveRoute.instance,
                  builder: (_, __) => Badge(
                    isLabelVisible: !ActiveRoute.instance.isEmpty,
                    label: Text('${ActiveRoute.instance.length}'),
                    backgroundColor: AppColors.ciniBordeaux,
                    child: AppIcon(icon, color: color, size: 28),
                  ),
                )
              : AppIcon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Dairesel QR Butonu (krem halkalı)
  Widget _buildQrButton() {
    final selected = _currentIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        width: _qrSize + 12,
        height: _qrSize + 12,
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: AppColors.bgCanvas,
          shape: BoxShape.circle,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.ciniBordeaux,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.ciniBordeaux.withValues(
                  alpha: selected ? 0.45 : 0.28,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: AppIcon('qr', color: Colors.white, size: 34),
          ),
        ),
      ),
    );
  }

  Widget _buildQrLabel() {
    final selected = _currentIndex == 2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = 2),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Text(
          context.t('nav_qr'),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primaryTeal : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
