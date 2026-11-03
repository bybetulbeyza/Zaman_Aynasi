import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/passport.dart';

/// Ana ekranda pasaport ilerlemesi: bir satır mühür yuvası. Kazanılanlar dolu, kalanlar silik görünür;
/// böylece "boş yerleri doldur" hissi verir. Dokununca pasaport açılır.
class PassportStrip extends StatelessWidget {
  final int total;
  final VoidCallback onTap;
  const PassportStrip({super.key, required this.total, required this.onTap});

  static const int _maxSlots = 7;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Passport.instance,
      builder: (context, _) {
        final n = Passport.instance.stampCount;
        final invite = n == 0 && !AuthService.isSignedIn;
        final done = total > 0 && n >= total;
        final slots = total < _maxSlots ? total : _maxSlots;
        return Semantics(
          button: true,
          label: context
              .t('passport_count')
              .replaceAll('{n}', '$n')
              .replaceAll('{total}', '$total'),
          excludeSemantics: true,
          onTap: onTap,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 16),
              decoration: ShapeDecoration(
                color: AppColors.primaryTealLight,
                shape: ContinuousRectangleBorder(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                    topRight: Radius.circular(44),
                    bottomLeft: Radius.circular(44),
                  ),
                  side: BorderSide(
                    color: AppColors.primaryTeal.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invite
                              ? context.t('strip_invite_title')
                              : context.t('passport_title'),
                          style: const TextStyle(
                            fontFamily: AppTheme.headingFont,
                            color: AppColors.primaryTealDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                          ),
                        ),
                      ),
                      Text(
                        context
                            .t('passport_count')
                            .replaceAll('{n}', '$n')
                            .replaceAll('{total}', '$total'),
                        style: const TextStyle(
                          color: AppColors.primaryTealDark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primaryTeal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [for (var i = 0; i < slots; i++) _slot(i < n)],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    done
                        ? context.t('strip_done')
                        : invite
                        ? context.t('strip_invite')
                        : context.t('strip_keep'),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textMuted,
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

  Widget _slot(bool earned) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: earned ? AppColors.primaryTeal : Colors.white,
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: earned ? 1 : 0.35),
          width: 1.4,
        ),
      ),
      child: Icon(
        earned ? Icons.check_rounded : Icons.workspace_premium_rounded,
        size: 20,
        color: earned
            ? Colors.white
            : AppColors.primaryTeal.withValues(alpha: 0.35),
      ),
    );
  }
}
