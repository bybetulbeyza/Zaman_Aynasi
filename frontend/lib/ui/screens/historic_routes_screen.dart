import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../widgets/common/squircle_frame.dart';
import '../widgets/common/dark_cancel.dart';
import '../widgets/common/logo_loader.dart';
import '../../core/constants/app_cities.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/state/active_route.dart';
import '../../core/utils/walking_route_service.dart';
import '../../core/constants/app_theme.dart';
import '../../data/models/heritage_place.dart';
import '../../data/models/heritage_route.dart';
import '../../data/repositories/heritage_repository.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/active_route_card.dart';
import '../widgets/common/app_network_image.dart';
import '../widgets/common/filter_chip_pill.dart';
import '../widgets/route/route_stops_sheet.dart';

class HistoricRoutesScreen extends StatefulWidget {
  /// Bir rota başlatılınca (veya aktif rota haritada gösterilince) haritaya geçmek için.
  final Function(List<HeritagePlace>)? onRouteStarted;

  /// Duraklar listesinde bir durağa dokununca: haritaya geçip o durağı gösterir.
  final void Function(List<HeritagePlace> stops, int index)? onShowStop;

  /// "Rota oluştur" butonu: rota oluşturma formunu açar.
  final VoidCallback? onCreateRoute;

  const HistoricRoutesScreen({
    super.key,
    this.onRouteStarted,
    this.onShowStop,
    this.onCreateRoute,
  });

  @override
  State<HistoricRoutesScreen> createState() => _HistoricRoutesScreenState();
}

class _HistoricRoutesScreenState extends State<HistoricRoutesScreen> {
  final HeritageRepository _repository = HeritageRepository();
  static const _cities = ['Tümü', ...AppCities.all];
  String _city = 'Tümü';
  List<HeritageRoute> _routes = [];
  bool _isLoading = true;
  final PageController _pc = PageController(viewportFraction: 0.84);
  int _page = 0;
  final GlobalKey _headerKey = GlobalKey();
  double _headerH = 0;

  /// Başlık bölümünün yüksekliğini ölçer; karusel kalan alanı dolduracak şekilde boylanır.
  void _measureHeader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final h = _headerKey.currentContext?.size?.height;
      if (mounted && h != null && (h - _headerH).abs() > 1) {
        setState(() => _headerH = h);
      }
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _repository
        .getPlaces()
        .then((p) {
          if (mounted) {
            setState(() {
              _routes = HeritageRoute.fromPlaces(p);
              _isLoading = false;
            });
            _loadWalkingData();
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _isLoading = false);
        });
  }

  /// Her rota için gerçek yürüyüş mesafesi ve süresini çeker; gelene kadar tahmin gösterilir.
  Future<void> _loadWalkingData() async {
    for (var i = 0; i < _routes.length; i++) {
      final route = _routes[i];
      WalkingRouteService.fetch(
        route.stops.map((s) => s.location).toList(),
      ).then((walk) {
        if (walk == null || !mounted) return;
        setState(() {
          final idx = _routes.indexWhere((r) => r.name == route.name);
          if (idx != -1) _routes[idx] = _routes[idx].withWalk(walk);
        });
      });
    }
  }

  void _start(HeritageRoute route) {
    ActiveRoute.instance.setRoute(
      route.stops,
      titleTr: route.name,
      titleEn: route.nameEn,
    );
    widget.onRouteStarted?.call(route.stops);
  }

  void _showStops(HeritageRoute route) {
    showRouteStopsSheet(
      context,
      route: route,
      onStopTap: (i) => widget.onShowStop?.call(route.stops, i),
      onStart: () => _start(route),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rota verisi şimdilik yalnızca aktif şehir (Bursa) için var
    final visible = (_city == 'Tümü' || AppCities.isAvailable(_city))
        ? _routes
        : <HeritageRoute>[];

    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, box) {
                    _measureHeader();
                    final carouselH = (box.maxHeight - _headerH - 56).clamp(
                      380.0,
                      680.0,
                    );
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
                      children: [
                        Column(
                          key: _headerKey,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                context.t('hr_title'),
                                style: AppTheme.displayLarge,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                children: _cities
                                    .map(
                                      (c) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: FilterChipPill(
                                          label: c == 'Tümü'
                                              ? context.t('all_filter')
                                              : c,
                                          selected: _city == c,
                                          onTap: () =>
                                              setState(() => _city = c),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _buildCreateRow(),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: ActiveRouteCard(
                                onShowOnMap: (stops) =>
                                    widget.onRouteStarted?.call(stops),
                              ),
                            ),
                          ],
                        ),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: LogoLoader(),
                          )
                        else if (visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                context
                                    .t('hr_soon')
                                    .replaceAll('{city}', _city),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          )
                        else
                          _buildCarousel(visible, carouselH),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Çiplerin altında, listeyi örtmeyen tam genişlikte "Rota oluştur" satırı.
  Widget _buildCreateRow() {
    return GestureDetector(
      onTap: widget.onCreateRoute,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryTealLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryTeal.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.t('rc_create'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTealDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primaryTeal,
            ),
          ],
        ),
      ),
    );
  }

  /// Büyük kartlı yatay karusel: ortadaki kart büyük, yanlardakiler küçük ve silik görünür.
  Widget _buildCarousel(List<HeritageRoute> routes, double height) {
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _pc,
            itemCount: routes.length,
            clipBehavior: Clip.none,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _pc,
              builder: (_, child) {
                var page = _page.toDouble();
                if (_pc.hasClients && _pc.position.haveDimensions) {
                  page = _pc.page ?? page;
                }
                final d = (page - i).abs().clamp(0.0, 1.0);
                return Transform.scale(scale: 1 - 0.08 * d, child: child);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: _card(routes[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < routes.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page
                      ? AppColors.primaryTeal
                      : AppColors.chipBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _glassChip(IconData icon, String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(HeritageRoute route) {
    final en = context.isEn;
    final cover = route.stops.first.imageAfterUrl;
    final thumbs = route.stops.take(4).toList();
    return Semantics(
      button: true,
      label: route.nameFor(en),
      onTap: () => _showStops(route),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _showStops(route),
        child: SquircleFrame(
          radius: 56,
          sharp: 10,
          gap: 5,
          child: DarkCancel(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cover.isNotEmpty)
                  AppNetworkImage(imageUrl: cover)
                else
                  const ColoredBox(color: AppColors.heroPetrol),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.3, 0.62, 1.0],
                      colors: [
                        Colors.transparent,
                        Color(0x660F2F3A),
                        Color(0xE60F2F3A),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: _glassChip(
                    Icons.place_outlined,
                    route.stops.first.city,
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.nameFor(en),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _glassChip(
                            Icons.flag_outlined,
                            '${route.stops.length} ${context.t('stops_word')}',
                          ),
                          _glassChip(
                            Icons.schedule_rounded,
                            route.durationLabelFor(en),
                          ),
                          _glassChip(
                            Icons.directions_walk_rounded,
                            route.distanceLabelFor(en),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Duraklardan küçük yuvarlak önizlemeler
                      SizedBox(
                        height: 38,
                        child: Stack(
                          children: [
                            for (var i = 0; i < thumbs.length; i++)
                              Positioned(
                                left: i * 26.0,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: AppNetworkImage(
                                      imageUrl: thumbs[i].imageAfterUrl,
                                    ),
                                  ),
                                ),
                              ),
                            if (route.stops.length > thumbs.length)
                              Positioned(
                                left: thumbs.length * 26.0,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  child: Text(
                                    '+${route.stops.length - thumbs.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // "Rotayı gör" kapsülü ve ok
                      Container(
                        height: 52,
                        padding: const EdgeInsets.fromLTRB(22, 0, 6, 0),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.t('hr_see_stops'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 22,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
