import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../widgets/common/app_network_image.dart';
import '../widgets/common/filter_chip_pill.dart';
import '../widgets/common/pill_button.dart';
import '../widgets/common/tulip_motif.dart';

/// Hazır rota paketi. Şimdilik örnek veri; backend'de rota tablosu olunca oradan gelecek.
class _RoutePackage {
  final String name;
  final String city;
  final int stops;
  final String duration;
  final String distance;

  const _RoutePackage(this.name, this.city, this.stops, this.duration, this.distance);
}

const _packages = [
  _RoutePackage('Han ve Çarşı Hattı', 'Bursa', 6, '2 sa 30 dk', '3,8 km'),
  _RoutePackage('Selçuklu İzleri', 'Konya', 5, '2 sa', '3,1 km'),
];

class HistoricRoutesScreen extends StatefulWidget {
  final Function(List<HeritagePlace>)? onRouteStarted;

  const HistoricRoutesScreen({super.key, this.onRouteStarted});

  @override
  State<HistoricRoutesScreen> createState() => _HistoricRoutesScreenState();
}

class _HistoricRoutesScreenState extends State<HistoricRoutesScreen> {
  final HeritageRepository _repository = HeritageRepository();
  static const _cities = ['Tümü', 'Bursa', 'Konya', 'Hatay', 'Kütahya'];
  String _city = 'Tümü';
  List<HeritagePlace> _places = [];

  @override
  void initState() {
    super.initState();
    _repository.getPlaces().then((p) {
      if (mounted) setState(() => _places = p);
    }).catchError((_) {});
  }

  void _start(_RoutePackage pkg) {
    if (_places.isEmpty) return;
    widget.onRouteStarted?.call(_places.take(pkg.stops).toList());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _packages.where((p) => _city == 'Tümü' || p.city == _city).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
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
                const Text('Tarihi Rotalar', style: AppTheme.displayLarge),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Bölgeye ve temaya göre hazır rota paketleri',
                style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _cities
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChipPill(
                            label: c,
                            selected: _city == c,
                            onTap: () => setState(() => _city = c),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('Bu şehir için henüz hazır rota yok.',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
            for (final pkg in visible) ...[
              _card(pkg),
              const SizedBox(height: 28),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(_RoutePackage pkg) {
    const radius = BorderRadius.all(Radius.circular(20));
    final cover = _places.isNotEmpty ? _places.first.imageAfterUrl : null;
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
                if (cover != null)
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
                const Positioned(top: 0, right: 0, child: TulipBadge()),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: Text(
                    pkg.name,
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
          '${pkg.city} · ${pkg.stops} durak · ${pkg.duration} · ${pkg.distance}',
          style: const TextStyle(fontSize: 14.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: PillButton.outlined('Durakları gör', onPressed: () => _start(pkg))),
            const SizedBox(width: 12),
            Expanded(child: PillButton('Rotayı başlat', onPressed: () => _start(pkg))),
          ],
        ),
      ],
    );
  }
}
