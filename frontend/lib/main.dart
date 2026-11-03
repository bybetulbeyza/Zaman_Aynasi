import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_theme.dart';
import 'core/analytics/analytics.dart';
import 'core/auth/auth_service.dart';
import 'core/l10n/app_lang.dart';
import 'core/state/app_accessibility.dart';
import 'core/state/passport.dart';
import 'ui/screens/reset_password_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/widgets/common/dark_cancel.dart';

/// E-postadaki şifre sıfırlama bağlantısı gibi dışarıdan gelen olaylarda ekran açabilmek için.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final DateTime _appStarted = DateTime.now();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Dashboard -> Project Settings -> API
  await Supabase.initialize(
    url: 'https://rozgcvedqcfunjmfhptj.supabase.co',
    anonKey: 'sb_publishable_KCU71TvdS3yGzepKYae-kQ_gIeZzBu_',
  );

  await Passport.instance.init();
  await AppAccessibility.instance.init();
  await Analytics.instance.init();
  Analytics.track('app_open');

  // Şifre sıfırlama bağlantısından dönüldüğünde yeni şifre ekranını aç
  AuthService.changes.listen((s) async {
    if (s.event != AuthChangeEvent.passwordRecovery) return;
    // Açılış ekranı bitmeden açılırsa onunla birlikte kapanabilir; kısa süre bekle
    final wait =
        const Duration(milliseconds: 3800) -
        DateTime.now().difference(_appStarted);
    if (!wait.isNegative) await Future<void>.delayed(wait);
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const ResetPasswordScreen()),
    );
  });

  runApp(const ZamanAynasiApp());
}

class ZamanAynasiApp extends StatelessWidget {
  const ZamanAynasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppAccessibility.instance,
      builder: (context, _) => _app(),
    );
  }

  Widget _app() {
    return AppLangScope(
      lang: AppLang.instance,
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        title: 'Zaman Aynası',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeFor(dark: false),
        darkTheme: AppTheme.themeFor(dark: true),
        themeMode: switch (AppAccessibility.instance.themeMode) {
          1 => ThemeMode.light,
          2 => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        builder: (context, child) => ListenableBuilder(
          listenable: AppAccessibility.instance,
          builder: (context, _) {
            final media = MediaQuery.of(context);
            final scaled = MediaQuery(
              data: media.copyWith(
                // Tam ekran tabletlerde üst boşluk 0 gelebilir; içerik kenara yapışmasın
                padding: media.padding.copyWith(
                  top: media.padding.top < 28 ? 28 : media.padding.top,
                ),
                textScaler: TextScaler.linear(
                  media.textScaler.scale(1) *
                      AppAccessibility.instance.textScale,
                ),
              ),
              child: child!,
            );
            final dark = AppAccessibility.instance.isDark(context);
            final themed = DarkScope(
              inverted: dark,
              child: dark
                  ? ColorFiltered(
                      colorFilter: AppAccessibility.darkFilter,
                      child: scaled,
                    )
                  : scaled,
            );
            return AppAccessibility.instance.highContrast
                ? ColorFiltered(
                    colorFilter: AppAccessibility.contrastFilter,
                    child: themed,
                  )
                : themed;
          },
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
