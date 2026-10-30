import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_lang.dart';
import '../widgets/common/pattern_background.dart';
import '../widgets/common/app_logo.dart';
import 'main_screen.dart';

/// Açılış ekranı: petrol zemin, çini deseni, lale logosu. Kısa süre sonra ana ekrana geçer.
class SplashScreen extends StatefulWidget {
  static const Duration duration = Duration(milliseconds: 2400);

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
    precacheImage(const AssetImage(PatternBackground.asset), context);
    precacheImage(const AssetImage(AppLogo.asset), context);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.heroPetrol,
      body: PatternBackground.onDark(
        child: SafeArea(
          child: Stack(
            children: [
              // İnce çift bordo çerçeve
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _frame(radius: 36, opacity: 0.75),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: _frame(radius: 30, opacity: 0.45),
                ),
              ),

              FadeTransition(
                opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    const AppLogo(size: 210, shadow: true),
                    const SizedBox(height: 34),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 36),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Zaman Aynası',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: 54,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB8283D),
                            shadows: [
                              Shadow(color: Color(0xAAD0344B), blurRadius: 18),
                              Shadow(color: Color(0x66D0344B), blurRadius: 36),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 56),
                      child: Text(
                        context.t('splash_tagline'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.4,
                          color: Color(0xFFF3EBDD),
                        ),
                      ),
                    ),
                    const Spacer(flex: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 44),
                      child: Text(
                        context.t('splash_credit'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xCCF3EBDD),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frame({required double radius, required double opacity}) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: AppColors.ciniBordeaux.withValues(alpha: opacity),
            width: 1.2,
          ),
        ),
      );
}
