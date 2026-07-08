// ignore_for_file: use_build_context_synchronously

import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;

import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';
import 'package:mysafar_sdk/src/view/splash/language_selection_page.dart';
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

class SplashScreen extends StatefulWidget {
  /// splash screen where user navigated to onboarding or home
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
  static const String routeName = "/";
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const double _logoSize = 136;
  static const Color _lightSplashBackground = Color(0xFFFFFFFF);
  static const Color _darkSplashBackground = Color(0xFF1C1C1C);

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });
    _controller.forward();
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final storage = sdkStorage();
    final isFirstTime = storage.read<bool>("isFirstTime") ?? true;

    if (isFirstTime) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        LanguageSelectionPage.routeName,
        (route) => false,
      );
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        BottomNavBarPage.routeName,
        (route) => false,
        arguments: 0,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.themeProvider.isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          isDark ? ProjectTheme.kStatusBarDark : ProjectTheme.kStatusBarLight,
      child: Scaffold(
        backgroundColor:
            isDark ? _darkSplashBackground : _lightSplashBackground,
        body: Center(
          child: FadeTransition(
            opacity: _animation,
            child: ScaleTransition(
              scale: _animation,
              child: SizedBox(
                width: _logoSize,
                height: _logoSize,
                child: Image.asset(Assets.splashSplashLogo),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
