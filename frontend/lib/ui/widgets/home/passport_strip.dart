import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/passport.dart';

/// Ana ekranda pasaport ilerlemesi: "3/25 mühür" ve ilerleme çubuğu. Dokununca pasaporta gider.
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
        return Semantics(
          button: true,
          label: context
              .t('passport_count')
              .replaceAll('{n}', '$n')
              .replaceAll('{total}', '$total'),
          excludeSemantics: true,
          onTap: onTap,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invite
                              ? context.t('strip_invite_title')
                              : context
                                    .t('passport_count')
                                    .replaceAll('{n}', '$n')
                                    .replaceAll('{total}', '$total'),
                          style: const TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : (n / total).clamp(0, 1),
                            minHeight: 7,
                            backgroundColor: Colors.white24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          done
                              ? context.t('strip_done')
                              : invite
                              ? context.t('strip_invite')
                              : context.t('strip_keep'),
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 28,
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
