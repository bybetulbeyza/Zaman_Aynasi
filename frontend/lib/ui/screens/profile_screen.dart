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

  void _showAccessibility(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      constraints: kSheetConstraints,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCanvas,
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
          return SafeArea(
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
                                    i == AppAccessibility.textScales.length - 1
                                    ? 0
                                    : 10,
                              ),
                              child: GestureDetector(
                                onTap: () => a11y.setTextScale(
                                  AppAccessibility.textScales[i],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        a11y.textScale ==
                                            AppAccessibility.textScales[i]
                                        ? AppColors.primaryTeal
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color:
                                          a11y.textScale ==
                                              AppAccessibility.textScales[i]
                                          ? AppColors.primaryTeal
                                          : AppColors.chipBorder,
                                    ),
                                  ),
                                  child: Text(
                                    labels[i],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color:
                                          a11y.textScale ==
                                              AppAccessibility.textScales[i]
                                          ? Colors.white
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primaryTeal,
                      title: Text(
                        context.t('high_contrast'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      value: a11y.highContrast,
                      onChanged: a11y.setHighContrast,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primaryTeal,
                      title: Text(
                        context.t('guide_prefer_text'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(context.t('guide_prefer_text_hint')),
                      value: a11y.readGuide,
                      onChanged: a11y.setReadGuide,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t('appearance'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final m in const [0, 1, 2])
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: m == 2 ? 0 : 10),
                              child: GestureDetector(
                                onTap: () => a11y.setThemeMode(m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: a11y.themeMode == m
                                        ? AppColors.primaryTeal
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: a11y.themeMode == m
                                          ? AppColors.primaryTeal
                                          : AppColors.chipBorder,
                                    ),
                                  ),
                                  child: Text(
                                    context.t(
                                      m == 0
                                          ? 'theme_system'
                                          : m == 1
                                          ? 'theme_light'
                                          : 'theme_dark',
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: a11y.themeMode == m
                                          ? Colors.white
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryTeal,
                            fontSize: 17,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PassportScreen()),
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
                const SizedBox(height: 14),
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
      padding: EdgeInsets.fromLTRB(signedIn ? 16 : 22, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          if (signedIn) ...[
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              onBackgroundImageError: avatar != null ? (_, _) {} : null,
              child: avatar == null
                  ? Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
                    color: Colors.white,
                  ),
                ),
                if (signedIn)
                  Text(
                    AuthService.user?.email ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (signedIn)
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 28,
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthScreen(popOnDone: true),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white70),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(context.t('auth_login')),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(
          horizontal: 22,
          vertical: trailing != null ? 11 : 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.chipBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 17, color: AppColors.textDark),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
          ],
        ),
      ),
    );
  }
}
