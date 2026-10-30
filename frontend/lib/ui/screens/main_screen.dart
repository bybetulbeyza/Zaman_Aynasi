import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onQrTap: () => setState(() => _currentIndex = 2),
        onCreateRouteTap: () => setState(() => _currentIndex = 3),
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
      RoutesScreen(
        onRouteCreated: (places) {
          setState(() => _currentIndex = 1); // Harita sekmesine geç
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapKey.currentState?.loadCustomRoute(places);
          });
        },
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
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
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Ana Sayfa',
                        index: 0,
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.place_outlined,
                        activeIcon: Icons.place_rounded,
                        label: 'Harita',
                        index: 1,
                      ),
                    ),
                    Expanded(child: _buildQrLabel()),
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.alt_route_rounded,
                        activeIcon: Icons.alt_route_rounded,
                        label: 'Rotalarım',
                        index: 3,
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profil',
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
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
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
          Icon(isSelected ? activeIcon : icon, color: color, size: 26),
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
                color: AppColors.ciniBordeaux.withValues(alpha: selected ? 0.45 : 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 30,
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
          'QR Okut',
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
