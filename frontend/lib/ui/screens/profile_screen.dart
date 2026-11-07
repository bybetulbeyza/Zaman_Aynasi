import '../../core/navigation/app_nav.dart';
import '../widgets/common/pill_button.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/action_card.dart';
import '../widgets/common/dark_cancel.dart';
import '../widgets/common/sheet_handle.dart';
import 'package:flutter/material.dart';
import '../widgets/common/feedback_sheet.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/lang_toggle.dart';
import '../widgets/common/app_logo.dart';
import '../../core/state/app_accessibility.dart';
import 'about_screen.dart';
import 'passport_screen.dart';
import '../../core/state/passport.dart';
import 'account_screen.dart';
import 'auth_screen.dart';
import '../../core/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Seçilebilir kutucuk: seçiliyken açık bordo zemin ve bordo çerçeve (ortak kart şekli).
  Widget _choiceTile(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final accent = bordeauxOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: appCardDecoration(
            round: 24,
            shadow: false,
            fill: selected ? AppColors.ciniBordeauxLight : Colors.white,
            side: selected ? accent : AppColors.chipBorder,
            width: selected ? 1.6 : 1.2,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? accent : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  /// Anahtarlı ayar satırı (ortak kart şekli, bordo anahtar).
  Widget _switchRow(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final accent = bordeauxOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
      decoration: appCardDecoration(
        round: 26,
        shadow: false,
        side: accent.withValues(alpha: 0.4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: accent,
            inactiveThumbColor: accent,
            inactiveTrackColor: AppColors.ciniBordeauxLight,
            trackOutlineColor: WidgetStatePropertyAll(
              accent.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccessibility(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      constraints: kSheetConstraints,
      clipBehavior: Clip.antiAlias,
      isScrollControlled: true,
      backgroundColor: canvasOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => ListenableBuilder(
        listenable: AppAccessibility.instance,
        builder: (_, __) {
          final a11y = AppAccessibility.instance;
          final labels = [
            context.t('font_normal'),
            context.t('font_large'),
            context.t('font_xlarge'),
          ];
          return PatternBackground(
            lineOpacity: 0.07,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SheetHandle(),
                      Text(context.t('font_row'), style: AppTheme.titleLarge),
                      const SizedBox(height: 18),
                      Text(
                        context.t('font_size'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (
                            var i = 0;
                            i < AppAccessibility.textScales.length;
                            i++
                          )
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right:
                                      i ==
                                          AppAccessibility.textScales.length - 1
                                      ? 0
                                      : 10,
                                ),
                                child: _choiceTile(
                                  context,
                                  labels[i],
                                  a11y.textScale ==
                                      AppAccessibility.textScales[i],
                                  () => a11y.setTextScale(
                                    AppAccessibility.textScales[i],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _switchRow(
                        context,
                        context.t('high_contrast'),
                        a11y.highContrast,
                        a11y.setHighContrast,
                      ),
                      const SizedBox(height: 10),
                      _switchRow(
                        context,
                        context.t('dark_mode_switch'),
                        a11y.isDark(context),
                        (v) => a11y.setThemeMode(v ? 2 : 1),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.record_voice_over_outlined,
                            size: 20,
                            color: bordeauxOf(context),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.t('a11y_reader_note'),
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('profile_title'), style: AppTheme.displayLarge),
                const SizedBox(height: 22),
                StreamBuilder<AuthState>(
                  stream: AuthService.changes,
                  builder: (context, _) => _accountCard(context),
                ),
                const SizedBox(height: 22),
                ListenableBuilder(
                  listenable: Passport.instance,
                  builder: (context, _) => _row(
                    context.t('passport_row'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${Passport.instance.stampCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: bordeauxOf(context),
                            fontSize: 17,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: bordeauxOf(context),
                        ),
                      ],
                    ),
                    onTap: () => AppNav.open(
                      context,
                      AppNav.passport,
                      (_) => const PassportScreen(),
                    ),
                  ),
                ),
                _row(
                  context.t('about_row'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
                _row(context.t('language_row'), trailing: const LangToggle()),
                _row(
                  context.t('font_row'),
                  onTap: () => _showAccessibility(context),
                ),
                _row(
                  context.t('feedback_row'),
                  onTap: () => FeedbackSheet.show(context),
                ),
                const SizedBox(
                  height: 66,
                ), // satırın 12 alt payıyla birlikte ~78: eskisinin üç katı
                Center(
                  child: Text(
                    context.t('profile_footer'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Center(child: AppLogo(size: 92)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountCard(BuildContext context) {
    final signedIn = AuthService.isSignedIn;
    final avatar = AuthService.avatarUrl;
    final name = AuthService.displayName;
    final body = Container(
      width: double.infinity,
      // Giriş yapılmamışken kart açık bordo, düğme beyaz: zıtlıkla dikkat çeker; biraz daha yüksek
      padding: signedIn
          ? const EdgeInsets.fromLTRB(16, 14, 14, 14)
          : const EdgeInsets.fromLTRB(22, 24, 16, 24),
      decoration: appCardDecoration(
        round: 34,
        fill: signedIn ? Colors.white : AppColors.ciniBordeauxLight,
        side: bordeauxOf(context).withValues(alpha: signedIn ? 0.4 : 0.55),
      ),
      child: Row(
        children: [
          if (signedIn) ...[
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.ciniBordeauxLight,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              onBackgroundImageError: avatar != null ? (_, _) {} : null,
              child: avatar == null
                  ? Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: bordeauxOf(context),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signedIn ? name : context.t('auth_signin_card'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (signedIn)
                  Text(
                    AuthService.user?.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (signedIn)
            Icon(
              Icons.chevron_right_rounded,
              color: bordeauxOf(context),
              size: 28,
            )
          else
            PillButton.outlined(
              context.t('auth_login'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(popOnDone: true),
                ),
              ),
            ),
        ],
      ),
    );
    if (!signedIn) return body;
    // Giriş yapılmışsa kartın tamamı hesap sayfasını açar
    return Semantics(
      button: true,
      label: '${context.t('acc_title')}: $name',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        ),
        child: body,
      ),
    );
  }

  Widget _row(String title, {VoidCallback? onTap, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ActionCard(
        title: title,
        trailing: trailing,
        onTap: onTap,
        round: 28,
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: trailing != null ? 9 : 15,
        ),
      ),
    );
  }
}
