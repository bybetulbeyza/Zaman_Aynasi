import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/lang_toggle.dart';
import '../widgets/common/tulip_motif.dart';
import '../../core/state/app_accessibility.dart';
import 'about_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t('coming_soon'))),
    );
  }

  void _showAccessibility(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('font_row'), style: AppTheme.titleLarge),
                  const SizedBox(height: 18),
                  Text(context.t('font_size'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < AppAccessibility.textScales.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: i == AppAccessibility.textScales.length - 1 ? 0 : 10),
                            child: GestureDetector(
                              onTap: () => a11y.setTextScale(AppAccessibility.textScales[i]),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: a11y.textScale == AppAccessibility.textScales[i]
                                      ? AppColors.primaryTeal
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: a11y.textScale == AppAccessibility.textScales[i]
                                        ? AppColors.primaryTeal
                                        : AppColors.chipBorder,
                                  ),
                                ),
                                child: Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: a11y.textScale == AppAccessibility.textScales[i]
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
                    title: Text(context.t('high_contrast'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    value: a11y.highContrast,
                    onChanged: a11y.setHighContrast,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternBackground(child: Scaffold(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('no_account'),
                      style: const TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t('no_account_body'),
                      style: const TextStyle(fontSize: 15, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _row(
                context.t('about_row'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              _row(context.t('language_row'), trailing: const LangToggle()),
              _row(context.t('font_row'), onTap: () => _showAccessibility(context)),
              _row(context.t('feedback_row'), onTap: () => _soon(context)),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  context.t('profile_footer'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted, height: 1.5),
                ),
              ),
              const SizedBox(height: 22),
              const Center(child: TulipMotif(height: 96)),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _row(String title, {VoidCallback? onTap, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: trailing != null ? 11 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.chipBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 17, color: AppColors.textDark)),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
