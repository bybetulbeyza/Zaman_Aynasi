import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/active_route.dart';
import '../../../data/models/heritage_place.dart';
import 'pill_button.dart';

/// "Aktif rotam" kartı: kullanıcının o anki rotasını listeler. Rota boşsa hiçbir şey çizmez.
class ActiveRouteCard extends StatelessWidget {
  final void Function(List<HeritagePlace> stops) onShowOnMap;

  const ActiveRouteCard({super.key, required this.onShowOnMap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ActiveRoute.instance,
      builder: (context, _) {
        final route = ActiveRoute.instance;
        if (route.isEmpty) return const SizedBox.shrink();
        final en = context.isEn;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.heroPetrol,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.titleFor(en) ?? context.t('ar_title'),
                      style: const TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: route.clear,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.t('ar_stops').replaceAll('{n}', '${route.length}'),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < route.stops.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
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
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          route.stops[i].nameFor(en),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => route.remove(route.stops[i]),
                        child: const Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 20,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  context.t('ar_show_map'),
                  onPressed: () => onShowOnMap(route.stops),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
