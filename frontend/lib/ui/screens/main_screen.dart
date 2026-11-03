import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth/auth_service.dart';
import 'auth_screen.dart';
import '../widgets/common/dark_cancel.dart';
import '../widgets/common/app_toast.dart';
import '../../core/state/passport.dart';
import '../widgets/passport/stamp_widget.dart';
import 'passport_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/state/active_route.dart';
import '../widgets/common/app_icon.dart';
import '../../data/models/heritage_place.dart';
import 'historic_routes_screen.dart';
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

/// Başka ekranlardan (örn. eser sayfası) ana ekrandaki bir sekmeye geçmek için.
final ValueNotifier<int?> mainTabRequest = ValueNotifier<int?>(null);

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Varsayılan olarak Ana Sayfa ile başlar
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    mainTabRequest.addListener(_onTabRequest);
    Passport.instance.ceremony.addListener(_onCeremony);
  }

  void _onCeremony() {
    final place = Passport.instance.ceremony.value;
    if (place == null || !mounted) return;
    Passport.instance.ceremony.value = null;
    showStampCeremony(
      context,
      place,
      onOpenPassport: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PassportScreen()),
      ),
    ).then((_) => _nudgeGuest());
  }

  /// Misafir ilk (ve üçüncü) mührünü kazanınca, kaybolmaması için hesaba kaydetmesini önerir.
  Future<void> _nudgeGuest() async {
    if (!mounted || AuthService.isSignedIn) return;
    final n = Passport.instance.stampCount;
    if (n != 1 && n != 3) return;
    try {
      final p = await SharedPreferences.getInstance();
      final shown = p.getInt('guest_nudge_shown') ?? 0;
      if (shown >= 2) return;
      await p.setInt('guest_nudge_shown', shown + 1);
    } catch (_) {}
    if (!mounted) return;
    AppToast.show(
      context,
      context.t('nudge_text'),
      icon: Icons.bookmark_added_outlined,
      actionLabel: context.t('auth_login'),
      duration: const Duration(seconds: 8),
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen(popOnDone: true)),
      ),
    );
  }

  void _onTabRequest() {
    final i = mainTabRequest.value;
    if (i == null || !mounted) return;
    mainTabRequest.value = null;
    setState(() => _currentIndex = i);
  }

  @override
  void dispose() {
    mainTabRequest.removeListener(_onTabRequest);
    Passport.instance.ceremony.removeListener(_onCeremony);
    super.dispose();
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
          onBrowseRoutes: () {
            Navigator.pop(context); // formu kapat, hazır rotalar sekmesine dön
            setState(() => _currentIndex = 3);
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

    // QR düğmesi çubuğun üstüne taşar; çubuğun üstünde beyaz boşluk kalmaması için
    // düğme Scaffold'un üstünde ayrı çizilir, çubuk yalnızca bordo çizgiden başlar.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: _buildBottomBar(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: safeBottom + _barHeight - (_qrSize + 12 - _qrRise),
          child: Center(child: _buildQrButton()),
        ),
      ],
    );
  }

  static const double _qrSize = 62;
  static const double _barHeight = 66;

  /// QR düğmesinin bordo çizginin ne kadar üstüne çıktığı
  static const double _qrRise = 23;

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(color: AppColors.dividerLine, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
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

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      onTap: () => setState(() => _currentIndex = index),
      child: GestureDetector(
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
                      backgroundColor: bordeauxOf(context),
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
      ),
    );
  }

  // Dairesel QR Butonu (krem halkalı)
  Widget _buildQrButton() {
    final selected = _currentIndex == 2;
    return Semantics(
      button: true,
      selected: selected,
      label: context.t('nav_qr'),
      excludeSemantics: true,
      onTap: () => setState(() => _currentIndex = 2),
      child: GestureDetector(
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
              color: bordeauxOf(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: bordeauxOf(
                    context,
                  ).withValues(alpha: selected ? 0.45 : 0.28),
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
      ),
    );
  }

  Widget _buildQrLabel() {
    final selected = _currentIndex == 2;
    return ExcludeSemantics(
      child: GestureDetector(
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
      ),
    );
  }
}
