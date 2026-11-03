import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/passport.dart';
import '../../../core/utils/location_service.dart';
import '../../../data/models/heritage_place.dart';
import '../common/app_network_image.dart';

/// Ana ekranda "sıradaki mühür" kartı: mührü henüz alınmamış en yakın eseri gösterir,
/// dokununca o esere gider. Sağdaki "3/23" rozeti pasaportu açar. Hepsi toplanınca tebrik gösterir.
/// Sıcak bej zemin ve altın çerçeve: uygulamanın krem zeminiyle uyumlu.
class PassportStrip extends StatelessWidget {
  /// Yakınlığa göre sıralı eserler (konum yoksa sıra önemsizdir).
  final List<HeritagePlace> places;
  final bool showDistance;
  final ValueChanged<HeritagePlace> onOpenPlace;
  final VoidCallback onOpenPassport;

  const PassportStrip({
    super.key,
    required this.places,
    required this.showDistance,
    required this.onOpenPlace,
    required this.onOpenPassport,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Passport.instance,
      builder: (context, _) {
        final en = context.isEn;
        final total = places.length;
        final n = Passport.instance.stampCount;
        final left = places
            .where((p) => !Passport.instance.hasStamp(p.id))
            .toList();
        final next = left.isEmpty ? null : left.first;
        final done = next == null;
        final count = context
            .t('passport_count')
            .replaceAll('{n}', '$n')
            .replaceAll('{total}', '$total');
        final distance = !done && showDistance && next.distanceMeters != null
            ? LocationService.formatDistance(next.distanceMeters)
            : '';

        final label = done
            ? context.t('strip_done')
            : n == 0
            ? context.t('next_stamp_first')
            : context.t('next_stamp');

        return Semantics(
          button: true,
          label: done
              ? '$label. $count'
              : '$label: ${next.nameFor(en)}. $count',
          excludeSemantics: true,
          onTap: done ? onOpenPassport : () => onOpenPlace(next),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: done ? onOpenPassport : () => onOpenPlace(next),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E6D0),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.ornamentGold.withValues(alpha: 0.55),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  if (done)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    )
                  else
                    AppNetworkImage(
                      imageUrl: next.imageAfterUrl,
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done ? count : next.nameFor(en),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTealDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done
                              ? ''
                              : distance.isEmpty
                              ? context.t('next_stamp_how')
                              : '$distance · ${context.t('next_stamp_how')}',
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
                  const SizedBox(width: 8),
                  // Pasaportu açan rozet
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onOpenPassport,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.ornamentGold.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$n/$total',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryTealDark,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primaryTeal,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
