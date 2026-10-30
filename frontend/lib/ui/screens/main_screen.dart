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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: const Border(
            top: BorderSide(color: AppColors.dividerLine, width: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Ana Sayfa',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.place_outlined,
                activeIcon: Icons.place_rounded,
                label: 'Harita',
                index: 1,
              ),
              _buildQrButton(),
              _buildNavItem(
                icon: Icons.alt_route_rounded,
                activeIcon: Icons.alt_route_rounded,
                label: 'Rotalarım',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                index: 4,
              ),
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
        children: [
          Icon(isSelected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Dairesel QR Butonu
  Widget _buildQrButton() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.ciniBordeaux,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ciniBordeaux.withOpacity(0.32),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'QR Okut',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}