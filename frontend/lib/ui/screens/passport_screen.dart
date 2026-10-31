import 'package:flutter/material.dart';
import '../widgets/common/app_back_button.dart';
import '../widgets/common/logo_loader.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/state/passport.dart';
import '../../data/models/heritage_place.dart';
import '../../data/repositories/heritage_repository.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/passport/stamp_widget.dart';
import 'slider_screen.dart';

/// Pasaport: her eser için bir mühür yuvası.
class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  List<HeritagePlace> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    HeritageRepository().getPlacesCached().then((p) {
      if (mounted) {
        setState(() {
          _all = p;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final en = context.isEn;
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: Passport.instance,
            builder: (context, _) {
              final cityPlaces = _all;
              final earned = cityPlaces
                  .where((p) => Passport.instance.hasStamp(p.id))
                  .length;
              final total = cityPlaces.length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      const AppBackButton(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.t('passport_title'),
                          style: AppTheme.displayLarge.copyWith(fontSize: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context
                              .t('passport_count')
                              .replaceAll('{n}', '$earned')
                              .replaceAll('{total}', '$total'),
                          style: const TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : earned / total,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.t('passport_hint'),
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: const LogoLoader()),
                    )
                  else
                    ..._grouped(context, cityPlaces, en),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Eserler şehre göre gruplanır; tek şehir varsa başlık gösterilmez.
  List<Widget> _grouped(
    BuildContext context,
    List<HeritagePlace> places,
    bool en,
  ) {
    final byCity = <String, List<HeritagePlace>>{};
    for (final p in places) {
      byCity.putIfAbsent(p.city, () => []).add(p);
    }
    final showTitles = byCity.length > 1;
    return [
      for (final e in byCity.entries) ...[
        if (showTitles)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(e.key, style: AppTheme.titleMedium),
          ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 18,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
          children: [for (final p in e.value) _slot(context, p, en)],
        ),
        const SizedBox(height: 18),
      ],
    ];
  }

  Widget _slot(BuildContext context, HeritagePlace p, bool en) {
    final has = Passport.instance.hasStamp(p.id);
    return Semantics(
      button: true,
      label:
          '${p.nameFor(en)}, ${has ? context.t('stamp_collected') : context.t('stamp_empty')}',
      excludeSemantics: true,
      onTap: () => _open(p),
      child: GestureDetector(
        onTap: () => _open(p),
        child: Column(
          children: [
            Expanded(
              child: FittedBox(
                child: StampWidget(place: p, earned: has, size: 96),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              p.nameFor(en),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.2,
                fontWeight: has ? FontWeight.w700 : FontWeight.w500,
                color: has ? AppColors.textDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(HeritagePlace p) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SliderScreen(place: p)),
  );
}
