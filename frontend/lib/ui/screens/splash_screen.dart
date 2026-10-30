import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../widgets/common/app_logo.dart';
import 'main_screen.dart';

/// Açılış ekranı: krem zeminde logo, marka adı, lale süslü ayraç ve slogan.
/// Kısa süre sonra ana ekrana geçer.
class SplashScreen extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 2400);
  static const String ornamentAsset = 'assets/images/tulip_ornament.png';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(SplashScreen.duration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(AppLogo.asset), context);
    precacheImage(const AssetImage(SplashScreen.ornamentAsset), context);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F0),
      body: SafeArea(
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: Column(
              children: [
                const Spacer(flex: 5),
                const AppLogo(size: 220),
                const SizedBox(height: 26),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Zaman Aynası',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: AppTheme.brandFont,
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        color: AppColors.logoNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Ortada küçük lale olan ince ayraç
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _line(),
                    const SizedBox(width: 12),
                    Image.asset(SplashScreen.ornamentAsset, height: 32),
                    const SizedBox(width: 12),
                    _line(),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  context.t('splash_motto'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3.4,
                    color: AppColors.logoNavy.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(flex: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Text(
                    context.t('splash_credit'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line() => Container(
    width: 64,
    height: 1.2,
    color: AppColors.logoNavy.withValues(alpha: 0.7),
  );
}
