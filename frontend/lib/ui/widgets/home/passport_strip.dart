import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/passport.dart';

/// Ana ekranda pasaport ilerlemesi. Sesli rehber kartıyla aynı renk paleti ve köşe şekli
/// (açık teal zemin, ince teal çerçeve, iki sivri iki kıvrımlı köşe); içeriği kendine özgü.
class PassportStrip extends StatelessWidget {
  final int total;
  final VoidCallback onTap;
  const PassportStrip({super.key, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Passport.instance,
      builder: (context, _) {
        final n = Passport.instance.stampCount;
        final invite = n == 0 && !AuthService.isSignedIn;
        final done = total > 0 && n >= total;
        final progress = total == 0 ? 0.0 : (n / total).clamp(0.0, 1.0);
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
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.primaryTeal,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                                  color: AppColors.primaryTealDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.5,
                                ),
                              ),
                            ),
                            Text(
                              '$n/$total',
                              style: const TextStyle(
                                color: AppColors.primaryTealDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: Colors.white,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          done
                              ? context.t('strip_done')
                              : invite
                              ? context.t('strip_invite')
                              : context.t('strip_keep'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryTeal,
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
