import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/widgets/edge_swipe_back.dart';

/// Embed rejimida tizim back (Android), predictive back va iOS chetdan swipe
/// UI orqaga tugmasi bilan bir xil ishlaydi: avval SDK ichki stack, oxirida
/// [MySafarSdk.exitEmbed].
///
/// [MaterialApp.builder] ichida turishi shart — nested navigator back eventini
/// host route'iga o'tkazib yubormasdan oldin ushlaydi.
class SdkEmbedBackHandler extends StatelessWidget {
  const SdkEmbedBackHandler({super.key, required this.child});

  final Widget child;

  /// `nav.pop()` chaqiruvi ichidagi qayta kiruvchi pop route'larini ajratish.
  static int _internalPopDepth = 0;

  static bool get isHandlingInternalPop => _internalPopDepth > 0;

  /// Tizim back (Android/iOS) — ichki route sinxron pop.
  /// `true` qaytarsa event qayta ishlandi.
  static bool handleSystemBack() {
    final nav = NavigationService.navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      _internalPopDepth++;
      try {
        nav.pop();
      } finally {
        _internalPopDepth--;
      }
      return true;
    }
    return false;
  }

  /// SDK ichki stack → pop; root → embed yopish (host ekraniga qaytish).
  static void handleBack() {
    if (handleSystemBack()) return;
    MySafarSdk.exitEmbed();
  }

  static bool get _atSdkRoot {
    final nav = NavigationService.navigatorKey.currentState;
    return nav == null || !nav.canPop();
  }

  @override
  Widget build(BuildContext context) {
    if (!MySafarSdk.isEmbedded) return child;

    return ValueListenableBuilder<int>(
      valueListenable: NavigationService.embedStackGeneration,
      builder: (context, _, __) {
        final atRoot = _atSdkRoot;
        return EdgeSwipeBack(
          enabled: atRoot,
          onBack: handleBack,
          child: child,
        );
      },
    );
  }
}
