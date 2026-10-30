import 'package:flutter/material.dart';
import '../../core/constants/app_cities.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/state/active_route.dart';
import '../../core/constants/app_theme.dart';
import '../../data/models/heritage_place.dart';
import '../../data/models/heritage_route.dart';
import '../../data/repositories/heritage_repository.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/app_network_image.dart';
import '../widgets/common/filter_chip_pill.dart';
import '../widgets/common/pill_button.dart';
import '../widgets/common/tulip_motif.dart';

class HistoricRoutesScreen extends StatefulWidget {
  final Function(List<HeritagePlace>)? onRouteStarted;

  const HistoricRoutesScreen({super.key, this.onRouteStarted});

  @override
  State<HistoricRoutesScreen> createState() => _HistoricRoutesScreenState();
}

class _HistoricRoutesScreenState extends State<HistoricRoutesScreen> {
  final HeritageRepository _repository = HeritageRepository();
  static const _cities = ['Tümü', ...AppCities.all];
  String _city = 'Tümü';
  List<HeritageRoute> _routes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository.getPlaces().then((p) {
      if (mounted) {
        setState(() {
          _routes = HeritageRoute.fromPlaces(p);
          _isLoading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _start(HeritageRoute route) {
    ActiveRoute.instance.setRoute(route.stops, titleTr: route.name, titleEn: route.nameEn);
    widget.onRouteStarted?.call(route.stops);
    Navigator.pop(context);
  }

  void _showStops(HeritageRoute route) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCanvas,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            children: [
              Text(route.nameFor(context.isEn), style: AppTheme.titleLarge),
              const SizedBox(height: 14),
              for (var i = 0; i < route.stops.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: AppColors.primaryTeal, shape: BoxShape.circle),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(route.stops[i].nameFor(context.isEn),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(route.stops[i].category.labelFor(context.isEn),
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textMuted)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rota verisi şimdilik yalnızca aktif şehir (Bursa) için var
    final visible =
        (_city == 'Tümü' || AppCities.isAvailable(_city)) ? _routes : <HeritageRoute>[];

    return PatternBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                Text(context.t('hr_title'), style: AppTheme.displayLarge),
              ],
            ),
            const SizedBox(height: 6),
            Text(context.t('hr_subtitle'),
                style: const TextStyle(fontSize: 15, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _cities
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChipPill(
                            label: c == 'Tümü' ? context.t('all_filter') : c,
                            selected: _city == c,
                            onTap: () => setState(() => _city = c),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryTeal)),
              )
            else if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(context.t('hr_soon').replaceAll('{city}', _city),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              ),
            for (final route in visible) ...[
              _card(route),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _card(HeritageRoute route) {
    const radius = BorderRadius.all(Radius.circular(20));
    final cover = route.stops.first.imageAfterUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 210,
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
                if (cover.isNotEmpty)
                  AppNetworkImage(imageUrl: cover)
                else
                  const ColoredBox(color: AppColors.heroPetrol),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.4, 1.0],
                      colors: [Colors.transparent, Color(0xCC0F2F3A)],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: Text(
                    route.nameFor(context.isEn),
                    style: const TextStyle(
                      fontFamily: AppTheme.headingFont,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${AppCities.active} · ${route.stops.length} ${context.t('stops_word')} · ${route.durationLabelFor(context.isEn)} · ${route.distanceLabelFor(context.isEn)}',
          style: const TextStyle(fontSize: 14.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: PillButton.outlined(context.t('hr_see_stops'), onPressed: () => _showStops(route))),
            const SizedBox(width: 12),
            Expanded(child: PillButton(context.t('hr_start'), onPressed: () => _start(route))),
          ],
        ),
      ],
    );
  }
}
