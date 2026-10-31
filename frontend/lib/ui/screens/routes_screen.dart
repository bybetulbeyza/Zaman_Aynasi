import 'package:flutter/material.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/logo_loader.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/category_style.dart';
import '../../core/utils/location_service.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../../core/constants/app_cities.dart';
import '../../core/constants/app_theme.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/filter_chip_pill.dart';
import '../widgets/common/app_icon.dart';
import '../widgets/common/pill_button.dart';
import '../widgets/common/app_logo.dart';
import '../../core/constants/app_categories.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/state/active_route.dart';

class RoutesScreen extends StatefulWidget {
  final Function(List<HeritagePlace>)? onRouteCreated;

  /// "Tarihi Rotalar'a göz at": hazır rotalar listesine döner.
  final VoidCallback? onBrowseRoutes;

  const RoutesScreen({super.key, this.onRouteCreated, this.onBrowseRoutes});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final HeritageRepository _repository = HeritageRepository();

  String _selectedCity = AppCities.active;
  int _selectedHours = 2; // 1, 2, 3 saat

  // Çoklu kategori seçimi (Envanter ve Harita ile aynı kategori listesi)
  late Set<PlaceCategory> _selectedCategories;

  List<HeritagePlace> _allPlaces = [];
  bool _isLoading = true;

  /// null = telefonun konumu; doluysa rota o eserden başlar.
  HeritagePlace? _startPlace;
  LatLng _userLocation = LocationService.defaultCenter;

  static const double _walkMetersPerMinute =
      58; // ≈ 4,5 km/s ve sokak dolambacı payı
  static const int _visitMinutes = 10; // durak başına ziyaret süresi

  @override
  void initState() {
    super.initState();
    _selectedCategories = {
      PlaceCategory.cami,
      PlaceCategory.han,
    }; // Görseldeki varsayılan seçililer
    _fetchPlaces();
    _resolveLocation();
  }

  /// Konumu bir kez çözer. Bursa'dan çok uzaktaysa (örn. yurt dışı) şehir merkezi kullanılır.
  Future<void> _resolveLocation() async {
    final loc = await LocationService.getCurrentLocation();
    final far =
        const Distance().as(
          LengthUnit.Kilometer,
          loc,
          LocationService.defaultCenter,
        ) >
        30;
    if (!mounted) return;
    setState(() => _userLocation = far ? LocationService.defaultCenter : loc);
  }

  Future<void> _fetchPlaces() async {
    try {
      final places = await _repository.getPlaces();
      if (mounted) {
        setState(() {
          _allPlaces = places;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Seçilen kategori, süre ve başlangıca göre rota planlar: en yakın durağı ekler,
  /// yürüme + ziyaret süresi seçilen süreyi aşmayana kadar devam eder.
  ({List<HeritagePlace> stops, int minutes}) _plan() {
    final pool = _allPlaces
        .where((p) => _selectedCategories.contains(p.category))
        .where((p) => p.id != _startPlace?.id)
        .toList();
    final budget = _selectedHours * 60;
    final stops = <HeritagePlace>[];
    var minutes = 0;
    var current = _startPlace?.location ?? _userLocation;

    if (_startPlace != null) {
      stops.add(_startPlace!);
      minutes += _visitMinutes;
    }

    const dist = Distance();
    while (pool.isNotEmpty) {
      pool.sort(
        (a, b) => dist
            .as(LengthUnit.Meter, current, a.location)
            .compareTo(dist.as(LengthUnit.Meter, current, b.location)),
      );
      final next = pool.first;
      final walk =
          dist.as(LengthUnit.Meter, current, next.location) /
          _walkMetersPerMinute;
      final total = minutes + walk + _visitMinutes;
      // En az bir durak her zaman eklenir
      if (total > budget && stops.isNotEmpty) break;
      stops.add(pool.removeAt(0));
      minutes = total.round();
      current = next.location;
    }
    return (stops: stops, minutes: minutes);
  }

  /// Başlangıç noktasını seçtirir: telefonun konumu ya da bir eser.
  Future<void> _pickStart() async {
    final en = context.isEn;
    final places = _allPlaces.where((p) => !p.isSubPlace).toList()
      ..sort((a, b) => a.nameFor(en).compareTo(b.nameFor(en)));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCanvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(context.t('rc_start'), style: AppTheme.titleLarge),
            const SizedBox(height: 14),
            _startTile(
              icon: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primaryTeal,
              ),
              label: context.t('rc_my_location'),
              selected: _startPlace == null,
              onTap: () {
                setState(() => _startPlace = null);
                Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: 16),
            Text(
              context.t('rc_start_from_place'),
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            for (final p in places)
              _startTile(
                icon: AppIcon(
                  CategoryStyle.of(p.category).icon,
                  size: 22,
                  color: CategoryStyle.of(p.category).color,
                ),
                label: p.nameFor(en),
                selected: _startPlace?.id == p.id,
                onTap: () {
                  setState(() => _startPlace = p);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _startTile({
    required Widget icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primaryTeal : AppColors.chipBorder,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 26, child: Center(child: icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryTeal,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreateRoute() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: const LogoLoader()),
    );

    final finalRoute = _plan().stops;

    if (mounted) {
      Navigator.pop(context); // Dialog kapat

      if (finalRoute.isEmpty) {
        AppToast.show(
          context,
          context.t('rc_none_found'),
          icon: Icons.search_off_rounded,
        );
        return;
      }

      ActiveRoute.instance.setRoute(
        finalRoute,
        titleTr: 'Özel rotam',
        titleEn: 'My custom route',
      );

      if (widget.onRouteCreated != null) {
        widget.onRouteCreated!(finalRoute);
      } else {
        AppToast.show(
          context,
          context.t('route_created').replaceAll('{n}', '${finalRoute.length}'),
        );
      }
    }
  }

  static const _fieldBg = Color(0xFFF6F0E3);

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    ),
  );

  Widget _field({required Widget child, EdgeInsets? padding}) => Container(
    width: double.infinity,
    padding:
        padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: _fieldBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.chipBorder),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(child: const LogoLoader())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Semantics(
                                button: true,
                                label: context.t('a11y_back'),
                                excludeSemantics: true,
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 20,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            context.t('rc_title'),
                            style: AppTheme.displayLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.chipBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context.t('rc_city')),
                            _field(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCity,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textDark,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontFamily: AppTheme.bodyFont,
                                    color: AppColors.textDark,
                                  ),
                                  items: AppCities.all
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          enabled: AppCities.isAvailable(c),
                                          child: Text(
                                            AppCities.isAvailable(c)
                                                ? c
                                                : '$c · ${context.t('soon')}',
                                            style: TextStyle(
                                              color: AppCities.isAvailable(c)
                                                  ? AppColors.textDark
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null)
                                      setState(() => _selectedCity = v);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _label(context.t('rc_start')),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _pickStart,
                              child: _field(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.ciniBordeaux,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _startPlace == null
                                            ? context.t('rc_my_location')
                                            : _startPlace!.nameFor(
                                                context.isEn,
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textDark,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _label(context.t('rc_duration')),
                            Row(
                              children: [1, 2, 3].map((h) {
                                final sel = _selectedHours == h;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: h != 3 ? 10 : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedHours = h),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 160,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? AppColors.primaryTeal
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                          border: Border.all(
                                            color: sel
                                                ? AppColors.primaryTeal
                                                : AppColors.chipBorder,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Text(
                                          '$h ${context.t('rc_hour')}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: sel
                                                ? Colors.white
                                                : AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),
                            _label(context.t('rc_types')),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: AppCategories.filters
                                  .whereType<PlaceCategory>()
                                  .map((cat) {
                                    final sel = _selectedCategories.contains(
                                      cat,
                                    );
                                    return FilterChipPill(
                                      label: cat.labelFor(context.isEn),
                                      icon: CategoryStyle.of(cat).icon,
                                      accent: CategoryStyle.of(cat).color,
                                      selected: sel,
                                      onTap: () => setState(() {
                                        if (sel) {
                                          if (_selectedCategories.length > 1) {
                                            _selectedCategories.remove(cat);
                                          }
                                        } else {
                                          _selectedCategories.add(cat);
                                        }
                                      }),
                                    );
                                  })
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                            Builder(
                              builder: (context) {
                                final plan = _plan();
                                return Text(
                                  context
                                      .t('rc_summary')
                                      .replaceAll('{n}', '${plan.stops.length}')
                                      .replaceAll('{m}', '${plan.minutes}'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textMuted,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: PillButton(
                                context.t('rc_create'),
                                onPressed: _handleCreateRoute,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              context.t('rc_ready_q'),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onBrowseRoutes,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  context.t('rc_browse'),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const AppLogo(size: 92),
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
