import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_theme.dart';
import 'ui/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Dashboard -> Project Settings -> API
  await Supabase.initialize(
    url: 'https://rozgcvedqcfunjmfhptj.supabase.co',
    anonKey: 'sb_publishable_KCU71TvdS3yGzepKYae-kQ_gIeZzBu_',
  );

  runApp(const ZamanAynasiApp());
}

class ZamanAynasiApp extends StatelessWidget {
  const ZamanAynasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zaman Aynası',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}