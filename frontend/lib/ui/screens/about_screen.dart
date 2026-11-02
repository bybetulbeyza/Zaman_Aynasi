import 'package:flutter/material.dart';
import '../widgets/common/app_back_button.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../../core/utils/launcher_util.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/pill_button.dart';
import '../widgets/common/section_title.dart';
import '../widgets/common/app_logo.dart';

/// Proje, amaç ve arşiv kaynaklarını tek sayfada toplar.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t('about_title'),
                      style: AppTheme.displayLarge.copyWith(fontSize: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionTitle(context.t('about_project')),
              const SizedBox(height: 10),
              _body(context.t('about_project_body')),
              const SizedBox(height: 26),
              SectionTitle(context.t('about_goal')),
              const SizedBox(height: 10),
              _body(context.t('about_goal_body')),
              const SizedBox(height: 26),
              SectionTitle(context.t('about_sources')),
              const SizedBox(height: 10),
              _body(context.t('about_sources_body')),
              const SizedBox(height: 16),
              PillButton.outlined(
                context.t('about_open_inventory'),
                onPressed: () => LauncherUtil.openUrl(
                  AppLinks.inventoryBooks,
                  source: 'about',
                ),
              ),
              const SizedBox(height: 26),
              SectionTitle(context.t('about_ai_title')),
              const SizedBox(height: 10),
              _body(context.t('about_ai_body')),
              const SizedBox(height: 26),
              SectionTitle(context.t('about_privacy_title')),
              const SizedBox(height: 10),
              _body(context.t('about_privacy_body')),
              const SizedBox(height: 32),
              const Center(child: AppLogo(size: 88)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      height: 1.55,
      color: AppColors.textDark,
    ),
  );
}
