import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;

class AirplaneBanner extends StatefulWidget {
  const AirplaneBanner({super.key});

  @override
  State<AirplaneBanner> createState() => _AirplaneBannerState();
}

class _AirplaneBannerState extends State<AirplaneBanner>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _planeController;
  late AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _planeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  void _startAnimations() {
    if (!_planeController.isAnimating) {
      _planeController.repeat(reverse: true);
    }
    if (!_cloudController.isAnimating) {
      _cloudController.repeat();
    }
  }

  void _stopAnimations() {
    _planeController.stop();
    _cloudController.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Ilova fonga o'tganda animatsiyalarni to'xtatamiz (GPU/CPU tejaladi),
    // qaytganda davom ettiramiz.
    if (state == AppLifecycleState.resumed) {
      _startAnimations();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _planeController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        height: 72,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0E557B),
                Color(0xFF4C9FBC),
              ],
              stops: [0.0, 0.724],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: context.shadowDown,
          ),
          // Outer Stack
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Clouds:
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 94, // same height
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _cloudController,
                    builder: (context, child) {
                      final offset = (_cloudController.value * 300) % 300;
                      return Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: -offset,
                            child: Row(
                              children: [
                                Image.asset(
                                  Assets.homeCloud,
                                  width: 300,
                                  fit: BoxFit.fill,
                                ),
                                Image.asset(
                                  Assets.homeCloud,
                                  width: 300,
                                  fit: BoxFit.fill,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // Plane: not clipped
              AnimatedBuilder(
                animation: _planeController,
                builder: (context, child) {
                  final double offset =
                      math.sin(_planeController.value * 2 * math.pi) * 8;
                  return Positioned(
                    top: -12 + offset,
                    left: -20,
                    child: Image.asset(
                      Assets.homeMainPlane,
                      height: 148,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
