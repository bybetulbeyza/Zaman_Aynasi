import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_theme.dart';
import 'core/l10n/app_lang.dart';
import 'core/state/app_accessibility.dart';
import 'core/state/passport.dart';
import 'ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Dashboard -> Project Settings -> API
  await Supabase.initialize(
    url: 'https://rozgcvedqcfunjmfhptj.supabase.co',
    anonKey: 'sb_publishable_KCU71TvdS3yGzepKYae-kQ_gIeZzBu_',
  );

  await Passport.instance.init();
  await AppAccessibility.instance.init();

  runApp(const ZamanAynasiApp());
}

class ZamanAynasiApp extends StatelessWidget {
  const ZamanAynasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLangScope(
      lang: AppLang.instance,
      child: MaterialApp(
        title: 'Zaman Aynası',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) => ListenableBuilder(
          listenable: AppAccessibility.instance,
          builder: (context, _) {
            final media = MediaQuery.of(context);
            final scaled = MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  media.textScaler.scale(1) *
                      AppAccessibility.instance.textScale,
                ),
              ),
              child: child!,
            );
            return AppAccessibility.instance.highContrast
                ? ColorFiltered(
                    colorFilter: AppAccessibility.contrastFilter,
                    child: scaled,
                  )
                : scaled;
          },
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
