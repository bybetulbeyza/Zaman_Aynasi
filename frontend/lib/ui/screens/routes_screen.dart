import '../widgets/common/app_card.dart';
import '../widgets/common/action_card.dart';
import '../widgets/common/sheet_handle.dart';
import 'package:flutter/material.dart';
import '../widgets/common/dark_cancel.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/logo_loader.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/category_style.dart';
import '../../core/utils/location_service.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../../core/constants/app_theme.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/filter_chip_pill.dart';
import '../widgets/common/app_icon.dart';
import '../widgets/common/pill_button.dart';
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
      constraints: kSheetConstraints,
      clipBehavior: Clip.antiAlias,
      isScrollControlled: true,
      backgroundColor: canvasOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, controller) => PatternBackground(
          lineOpacity: 0.07,
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const SheetHandle(),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
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
      child: ActionCard(
        leading: SizedBox(width: 26, child: Center(child: icon)),
        title: label,
        selected: selected,
        round: 22,
        onTap: onTap,
        trailing: selected ? null : const SizedBox.shrink(),
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
          bottomMargin: 24,
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

  /// Numaralı adım başlığı: "1  Nereden başlıyorsun?"
  Widget _step(int n, String title, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryTeal,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$n',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Seçilebilir büyük kutucuk (başlangıç ve süre seçenekleri için ortak görünüm).
  Widget _optionTile({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
    String? semanticLabel,
  }) => Semantics(
    button: true,
    selected: selected,
    label: semanticLabel,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: appCardDecoration(
          round: 22,
          shadow: false,
          fill: selected ? AppColors.primaryTealLight : Colors.white,
          side: selected ? AppColors.primaryTeal : AppColors.chipBorder,
          width: selected ? 1.8 : 1.2,
        ),
        child: child,
      ),
    ),
  );

  Widget _startOptions() {
    final fromPlace = _startPlace != null;
    Widget tile({
      required bool selected,
      required IconData icon,
      required String title,
      required String sub,
      required VoidCallback onTap,
    }) => Expanded(
      child: _optionTile(
        selected: selected,
        onTap: onTap,
        semanticLabel: '$title, $sub',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.primaryTeal : AppColors.textMuted,
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: AppColors.primaryTeal,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
    return Row(
      children: [
        tile(
          selected: !fromPlace,
          icon: Icons.my_location_rounded,
          title: context.t('rc_my_location'),
          sub: context.t('rc_my_location_sub'),
          onTap: () => setState(() => _startPlace = null),
        ),
        const SizedBox(width: 10),
        tile(
          selected: fromPlace,
          icon: Icons.account_balance_rounded,
          title: fromPlace
              ? _startPlace!.nameFor(context.isEn)
              : context.t('rc_from_place'),
          sub: fromPlace
              ? context.t('rc_change')
              : context.t('rc_from_place_sub'),
          onTap: _pickStart,
        ),
      ],
    );
  }

  Widget _durationOptions() => Row(
    children: [1, 2, 3].map((h) {
      final sel = _selectedHours == h;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: h != 3 ? 10 : 0),
          child: _optionTile(
            selected: sel,
            onTap: () => setState(() => _selectedHours = h),
            semanticLabel: '$h ${context.t('rc_hour')}',
            child: Center(
              child: Text(
                '$h ${context.t('rc_hour')}',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: sel ? AppColors.primaryTeal : AppColors.textDark,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _categoryChips() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: AppCategories.filters.whereType<PlaceCategory>().map((cat) {
      final sel = _selectedCategories.contains(cat);
      // Tüm seçili çipler aynı renkte (teal): neyin seçili olduğu tek bakışta anlaşılsın
      return FilterChipPill(
        label: cat.labelFor(context.isEn),
        icon: CategoryStyle.of(cat).icon,
        selected: sel,
        onTap: () => setState(() {
          if (sel) {
            if (_selectedCategories.length > 1) _selectedCategories.remove(cat);
          } else {
            _selectedCategories.add(cat);
          }
        }),
      );
    }).toList(),
  );

  /// Canlı önizleme: seçimlere göre çıkacak rotanın durakları ve süresi.
  Widget _preview(({List<HeritagePlace> stops, int minutes}) plan) {
    final en = context.isEn;
    final stops = plan.stops;
    const maxShown = 5;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: appCardDecoration(
        round: 26,
        shadow: false,
        fill: AppColors.creamSoft,
        side: AppColors.ornamentGold,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                size: 20,
                color: AppColors.primaryTeal,
              ),
              const SizedBox(width: 8),
              Text(
                context.t('rc_preview'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                context
                    .t('rc_preview_stats')
                    .replaceAll('{n}', '${stops.length}')
                    .replaceAll('{m}', '${plan.minutes}'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (stops.isEmpty)
            Text(
              context.t('rc_none_found'),
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            )
          else
            for (var i = 0; i < stops.length && i < maxShown; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryTeal,
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stops[i].nameFor(en),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          if (stops.length > maxShown)
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                context
                    .t('rc_more_stops')
                    .replaceAll('{n}', '${stops.length - maxShown}'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            context.t('rc_preview_note'),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _isLoading ? (stops: <HeritagePlace>[], minutes: 0) : _plan();
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: LogoLoader())
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const AppBackButton(),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        context.t('rc_title'),
                                        style: AppTheme.displayLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                _step(1, context.t('rc_q_start')),
                                _startOptions(),
                                const SizedBox(height: 26),
                                _step(2, context.t('rc_q_time')),
                                _durationOptions(),
                                const SizedBox(height: 26),
                                _step(
                                  3,
                                  context.t('rc_types'),
                                  hint: context.t('rc_types_hint'),
                                ),
                                _categoryChips(),
                                const SizedBox(height: 26),
                                _preview(plan),
                                const SizedBox(height: 24),
                                Center(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 6,
                                    children: [
                                      Text(
                                        context.t('rc_ready_q'),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: widget.onBrowseRoutes,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Text(
                                            context.t('rc_browse'),
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: bordeauxOf(context),
                                            ),
                                          ),
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
                    ),
                    // Sabit alt düğme: kaydırmadan her zaman görünür
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                      decoration: BoxDecoration(
                        color: canvasOf(context),
                        boxShadow: [
                          BoxShadow(
                            color: shadowOf(context, 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: SizedBox(
                            width: double.infinity,
                            child: PillButton(
                              plan.stops.isEmpty
                                  ? context.t('rc_create')
                                  : context
                                        .t('rc_create_n')
                                        .replaceAll(
                                          '{n}',
                                          '${plan.stops.length}',
                                        ),
                              onPressed: plan.stops.isEmpty
                                  ? null
                                  : _handleCreateRoute,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
