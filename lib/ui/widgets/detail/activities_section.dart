import '../../../core/navigation/app_nav.dart';
import '../../screens/passport_screen.dart';
import '../../screens/qr_scanner_screen.dart';
import '../common/app_card.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/passport.dart';
import '../../../data/models/heritage_place.dart';
import '../../../data/models/place_activity.dart';
import '../../../data/repositories/activity_repository.dart';
import '../common/section_title.dart';

/// Eser sayfasındaki "Keşif görevleri": yatay kaydırmalı, işaretlenebilir kartlar.
/// Görev yoksa (tablo boş / yüklenemedi) hiç görünmez.
class ActivitiesSection extends StatefulWidget {
  final HeritagePlace place;

  /// Değeri her değiştiğinde bölüm başlığı ve kartlar kısa bir "buradayız" animasyonu yapar.
  final ValueListenable<int>? pulse;
  const ActivitiesSection({super.key, required this.place, this.pulse});

  @override
  State<ActivitiesSection> createState() => _ActivitiesSectionState();
}

class _ActivitiesSectionState extends State<ActivitiesSection>
    with SingleTickerProviderStateMixin {
  List<PlaceActivity> _items = const [];

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  void _onPulse() {
    if (mounted) _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    widget.pulse?.removeListener(_onPulse);
    _pulse.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.pulse?.addListener(_onPulse);
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
            // Mühür kartından gelinince yalnızca başlık bir kez büyüyüp küçülür; sağdaki sayaç sabit kalır
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) {
                      final wave = math.sin(_pulse.value * math.pi);
                      return Transform.scale(
                        scale: 1 + 0.12 * wave,
                        alignment: Alignment.centerLeft,
                        child: child,
                      );
                    },
                    child: SectionTitle(context.t('act_title')),
                  ),
                ),
                const SizedBox(width: 12),
                // Sayaca dokununca pasaport açılır (mühürler orada birikir)
                Semantics(
                  button: true,
                  label: context.t('passport_title'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => AppNav.open(
                      context,
                      AppNav.passport,
                      (_) => const PassportScreen(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            size: 16,
                            color: AppColors.primaryTeal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$done/${_items.length} · ${context.t('passport_title')}',
                            style: const TextStyle(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.primaryTeal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
        // Eser sayfası kapanmasın: tarayıcı bu sayfanın üstünde açılır, geri ile buraya dönülür
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) =>
                QRScannerScreen(pushed: true, returnToPlaceId: widget.place.id),
          ),
        );
      }
      return;
    }
    Passport.instance.toggleActivity(a, widget.place, _items);
  }
}
