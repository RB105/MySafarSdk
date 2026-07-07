import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});
  static const String routeName = "onBoarding";

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnBoardingModel> _pages = [
    _OnBoardingModel(
      img: Assets.splashFirstOnboarding,
      background: Assets.splashBgWave1,
      title: "onboard_page1_title".tr(),
      subtitle: "onboard_page1_subtitle".tr(),
    ),
    _OnBoardingModel(
      img: Assets.splashGlobeIcon,
      background: Assets.splashBgWave2,
      title: "onboard_page2_title".tr(),
      subtitle: "onboard_page2_subtitle".tr(),
    ),
    _OnBoardingModel(
      img: Assets.splashBaggageIcon,
      background: Assets.splashBgWave3,
      title: "onboard_page3_title".tr(),
      subtitle: "onboard_page3_subtitle".tr(),
    ),
    _OnBoardingModel(
      img: Assets.splashHourIcon,
      background: Assets.splashBgWave4,
      title: "onboard_page4_title".tr(),
      subtitle: "onboard_page4_subtitle".tr(),
    )
  ];

  late final AnimationController _lottieController;
  bool _isPlaneFlying = false;
  late final AnimationController _planeSlideController;
  late final Animation<Offset> _planeEntryAnimation;
  late final Animation<Offset> _planeExitAnimation;
  bool _showEntryAnimation = true;

  @override
  void initState() {
    super.initState();

    _planeSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _planeEntryAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _planeSlideController,
      curve: Curves.easeInOut,
    ));

    _planeExitAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1, 0),
    ).animate(CurvedAnimation(
      parent: _planeSlideController,
      curve: Curves.easeInOut,
    ));

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _showEntryAnimation = true;
      });
      _planeSlideController.forward();
    });

    _lottieController = AnimationController(vsync: this)
      ..duration = const Duration(seconds: 2)
      ..addStatusListener((status) {
        if (!mounted) return;
        if (status == AnimationStatus.completed &&
            _currentPage == _pages.length - 1) {
          _finishOnboarding();
        }
      });
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      AnalyticsService()
          .trackButtonTap('onboarding_next', extra: {'page': _currentPage});
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      AnalyticsService().trackButtonTap('onboarding_complete');
      setState(() {
        _isPlaneFlying = true;
        _showEntryAnimation = false;
      });
      _planeSlideController
        ..reset()
        ..forward();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        _finishOnboarding();
      });
    }
  }

  void _finishOnboarding() {
    GetStorage().write('isFirstTime', false);
    Navigator.of(context).pushNamedAndRemoveUntil(
      BottomNavBarPage.routeName,
      (route) => false,
      arguments: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return SafeArea(
        top: Platform.isAndroid,
        bottom: Platform.isAndroid,
        child: Scaffold(
          appBar: AppBar(
            leading: SizedBox.shrink(),
            elevation: 0,
            backgroundColor: context.themeProvider.isDark
                ? ProjectTheme.backgroundDark
                : ProjectTheme.backgroundLight,
            actions: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: isLastPage == false
                    ? TextButton(
                        key: ValueKey("skip_button"),
                        onPressed: () {
                          AnalyticsService().trackButtonTap('onboarding_skip');
                          _finishOnboarding();
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "skip".tr(),
                              style: TextStyle(
                                color: ProjectTheme.brandColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.navigate_next,
                                size: 28, color: ProjectTheme.brandColor),
                          ],
                        ),
                      )
                    : SizedBox.shrink(key: ValueKey("empty")),
              ),
            ],
          ),
          body: Stack(
            children: [
              AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  final page = _pageController.hasClients
                      ? _pageController.page ?? 0.0
                      : 0.0;
                  final flightOffset =
                      _isPlaneFlying ? -context.width * 1.5 : 0.0;
                  return Stack(
                    children: List.generate(_pages.length, (index) {
                      final baseOffset = (index - page) * context.width;
                      return Positioned(
                        bottom: 0,
                        child: Transform.translate(
                          offset: Offset(baseOffset + flightOffset, 0),
                          child: Image.asset(
                            _pages[index].background,
                            fit: BoxFit.cover,
                            height: context.height * 0.35,
                            width: context.width,
                            color: context.themeProvider.isDark
                                ? const Color(0xff2F2F2F)
                                : const Color(0xffD5DEE8),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final isActive = _currentPage == index;
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: isActive ? 1.0 : 0.0,
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 800),
                          top: _isPlaneFlying ? -context.height : 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              SizedBox(
                                height: context.height * 0.1,
                              ),
                              const SizedBox(height: 48),
                              Image.asset(
                                page.img,
                                height: 72,
                                width: 72,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 32),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 48),
                                child: Column(
                                  children: [
                                    Text(
                                      page.title,
                                      style: context.textTheme.titleLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      page.subtitle,
                                      style: context.textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                bottom: _isPlaneFlying ? -100 : 80,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (indexDot) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == indexDot ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == indexDot
                            ? ProjectTheme.brandColor
                            : const Color(0xff8E8E92),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 160,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _showEntryAnimation
                      ? _planeEntryAnimation
                      : _planeExitAnimation,
                  child: Center(
                    child: Lottie.asset(
                      Assets.splashPlaneAnimation,
                      height: 160,
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: AnimatedSlide(
            duration: const Duration(milliseconds: 600),
            offset: _isPlaneFlying ? const Offset(0, 2) : Offset.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProjectTheme.brandColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isLastPage ? "start".tr() : "next".tr(),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lottieController.dispose();
    _planeSlideController.dispose();
    super.dispose();
  }
}

class _OnBoardingModel {
  final String img;
  final String background;
  final String title;
  final String subtitle;

  _OnBoardingModel({
    required this.img,
    required this.background,
    required this.title,
    required this.subtitle,
  });
}
