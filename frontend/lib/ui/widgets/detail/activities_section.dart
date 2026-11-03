import '../common/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/passport.dart';
import '../../../data/models/heritage_place.dart';
import '../../../data/models/place_activity.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../screens/main_screen.dart' show mainTabRequest;
import '../common/section_title.dart';

/// Eser sayfasındaki "Keşif görevleri": yatay kaydırmalı, işaretlenebilir kartlar.
/// Görev yoksa (tablo boş / yüklenemedi) hiç görünmez.
class ActivitiesSection extends StatefulWidget {
  final HeritagePlace place;
  const ActivitiesSection({super.key, required this.place});

  @override
  State<ActivitiesSection> createState() => _ActivitiesSectionState();
}

class _ActivitiesSectionState extends State<ActivitiesSection> {
  List<PlaceActivity> _items = const [];

  @override
  void initState() {
    super.initState();
    ActivityRepository.forPlace(widget.place.id).then((list) {
      if (mounted) setState(() => _items = list);
    });
  }

  static IconData _icon(String kind) {
    switch (kind) {
      case 'gor':
        return Icons.visibility_outlined;
      case 'tat':
        return Icons.local_cafe_outlined;
      case 'yap':
        return Icons.directions_walk_rounded;
      case 'fotograf':
        return Icons.photo_camera_outlined;
      case 'qr':
        return Icons.qr_code_scanner_rounded;
      case 'dinlen':
        return Icons.headphones_outlined;
      default:
        return Icons.explore_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final en = context.isEn;
    return ListenableBuilder(
      listenable: Passport.instance,
      builder: (context, _) {
        final p = Passport.instance;
        final done = p.doneCount(_items);
        final all = done == _items.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              context.t('act_title'),
              actionLabel: '$done/${_items.length}',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 208,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _card(context, _items[i], en),
              ),
            ),
            if (all) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: AppColors.primaryTeal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.t('act_all_done'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 26),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, PlaceActivity a, bool en) {
    final done = Passport.instance.isDone(a.id);
    return Semantics(
      button: true,
      checked: done,
      label: a.titleFor(en),
      hint: a.descriptionFor(en),
      excludeSemantics: true,
      onTap: () => _toggle(a),
      child: GestureDetector(
        onTap: () => _toggle(a),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 250,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
          decoration: appCardDecoration(
            round: 30,
            shadow: false,
            fill: done ? AppColors.primaryTealLight : Colors.white,
            side: done
                ? AppColors.primaryTeal.withValues(alpha: 0.5)
                : AppColors.chipBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.primaryTeal
                          : AppColors.primaryTealLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _icon(a.kind),
                      size: 19,
                      color: done ? Colors.white : AppColors.primaryTeal,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 26,
                    color: done ? AppColors.primaryTeal : AppColors.chipBorder,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                a.titleFor(en),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  a.descriptionFor(en),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (a.source.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      a.sourceFor(en),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(PlaceActivity a) {
    HapticFeedback.selectionClick();
    // QR görevi işaretlenerek değil, gerçekten okutularak tamamlanır: tarayıcıya götürür
    if (a.isQr) {
      if (!Passport.instance.isDone(a.id)) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        mainTabRequest.value = 2;
      }
      return;
    }
    Passport.instance.toggleActivity(a, widget.place, _items);
  }
}
