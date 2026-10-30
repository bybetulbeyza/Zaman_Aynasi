import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/location_service.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../../core/constants/app_cities.dart';
import '../../core/constants/app_theme.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/filter_chip_pill.dart';
import '../widgets/common/pill_button.dart';
import '../widgets/common/app_logo.dart';
import '../../core/constants/app_categories.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/state/active_route.dart';

class RoutesScreen extends StatefulWidget {
  final Function(List<HeritagePlace>)? onRouteCreated;

  const RoutesScreen({super.key, this.onRouteCreated});

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

  @override
  void initState() {
    super.initState();
    _selectedCategories = {PlaceCategory.cami, PlaceCategory.han}; // Görseldeki varsayılan seçililer
    _fetchPlaces();
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

  // Dinamik durak sayısı tahmini (Süre ve kategoriye göre)
  int get _calculatedStopsCount {
    if (_allPlaces.isEmpty) return _selectedHours * 2;
    // Seçili kategorilere uyan eserleri say
    final matchingCount =
        _allPlaces.where((p) => _selectedCategories.contains(p.category)).length;

    // Saat başına ortalama 2-3 durak gezilebilir
    final maxByTime = _selectedHours * 3;
    final stops = matchingCount > 0 ? matchingCount.clamp(1, maxByTime) : (_selectedHours * 2);
    return stops;
  }

  Future<void> _handleCreateRoute() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );

    final userLocation = await LocationService.getCurrentLocation();

    // Filtreleme: Seçili kategorilere göre eserleri al
    List<HeritagePlace> pool = _allPlaces
        .where((p) => _selectedCategories.isEmpty || _selectedCategories.contains(p.category))
        .toList();

    if (pool.isEmpty) pool = List.from(_allPlaces);

    // TSP Algoritması ile zikzaksız sırala
    final optimized = LocationService.optimizeRouteOrder(
      places: pool,
      startLocation: userLocation,
    );

    // Süreye göre durak sayısını sınırla
    final finalRoute = optimized.take(_calculatedStopsCount).toList();

    if (mounted) {
      Navigator.pop(context); // Dialog kapat

      ActiveRoute.instance.setRoute(
        finalRoute,
        titleTr: 'Özel rotam',
        titleEn: 'My custom route',
      );

      if (widget.onRouteCreated != null) {
        widget.onRouteCreated!(finalRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(context.t('route_created').replaceAll('{n}', '${finalRoute.length}')),
              ],
            ),
            backgroundColor: AppColors.primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  static const _fieldBg = Color(0xFFF6F0E3);

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
      );

  Widget _field({required Widget child, EdgeInsets? padding}) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.chipBorder),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return PatternBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.arrow_back_ios_new,
                                size: 20, color: AppColors.textDark),
                          ),
                        ),
                        Text(context.t('rc_title'), style: AppTheme.displayLarge),
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
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCity,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textDark),
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontFamily: AppTheme.bodyFont,
                                    color: AppColors.textDark),
                                items: AppCities.all
                                    .map((c) => DropdownMenuItem(
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
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _selectedCity = v);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _label(context.t('rc_start')),
                          _field(
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                      color: AppColors.ciniBordeaux,
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 12),
                                Text(context.t('rc_my_location'),
                                    style: const TextStyle(
                                        fontSize: 17, color: AppColors.textDark)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.chipBorder),
                                  ),
                                  child: Text(context.t('rc_now'),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _label(context.t('rc_duration')),
                          Row(
                            children: [1, 2, 3].map((h) {
                              final sel = _selectedHours == h;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: h != 3 ? 10 : 0),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedHours = h),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 14),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? AppColors.primaryTeal
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(26),
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
                              final sel = _selectedCategories.contains(cat);
                              return FilterChipPill(
                                label: cat.labelFor(context.isEn),
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
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            context
                                .t('rc_summary')
                                .replaceAll('{n}', '$_calculatedStopsCount')
                                .replaceAll('{h}', '$_selectedHours'),
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: PillButton(context.t('rc_create'),
                                onPressed: _handleCreateRoute),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Center(child: AppLogo(size: 92)),
                  ],
                ),
              ),
      ),
    ));
  }
}
