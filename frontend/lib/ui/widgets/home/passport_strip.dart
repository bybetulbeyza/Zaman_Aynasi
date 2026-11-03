import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_lang.dart';
import '../../../core/state/passport.dart';
import '../detail/guide_card.dart';

/// Ana ekranda pasaport ilerlemesi; sesli rehber kartıyla aynı tasarım dilinde.
/// Düğme bir mühür simgesi, ses dalgası yerine mühür sayısına göre dolan dalga çubuğu.
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
            child: GuideCard(
              playing: false,
              onTap: onTap,
              idleIcon: Icons.workspace_premium_rounded,
              title: invite
                  ? context.t('strip_invite_title')
                  : context.t('passport_title'),
              trailing: '$n/$total',
              bottom: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Waveform(progress: progress, height: 24),
                  const SizedBox(height: 6),
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
          ),
        );
      },
    );
  }
}
