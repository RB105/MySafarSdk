import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/widgets/edge_swipe_back.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';

/// Embed rejimida tizim back (Android), predictive back va iOS chetdan swipe
/// UI orqaga tugmasi bilan bir xil ishlaydi:
/// 1) SDK ichki stack → pop
/// 2) non-home tab (profil / buyurtmalar / yo'nalishlar) → Main
/// 3) Main → bir marta orqaga → [MySafarSdk.exitEmbed] (UI ← tugmasi bilan
///    bir xil, toast yo'q)
///
/// [MaterialApp.builder] ichida turishi shart — nested navigator back eventini
/// host route'iga o'tkazib yubormasdan oldin ushlaydi.
class SdkEmbedBackHandler extends StatelessWidget {
  const SdkEmbedBackHandler({super.key, required this.child});

  final Widget child;

  /// `nav.pop()` chaqiruvi ichidagi qayta kiruvchi pop route'larini ajratish.
  static int _internalPopDepth = 0;

  static bool get isHandlingInternalPop => _internalPopDepth > 0;

  /// PopScope + didPopRoute bir gesture'da ikki marta kelishini yutish.
  /// Shusiz bitta back tab → Main qilib, darhol SDK'ni ham yopib yuborardi.
  /// Foydalanuvchining keyingi bosishi odatda undan kechroq.
  static const Duration rootBackLock = Duration(milliseconds: 400);

  static bool _rootBackLocked = false;

  /// Testda root-back lock holatini tozalash.
  @visibleForTesting
  static void reset() {
    _rootBackLocked = false;
  }

  /// Tizim back (Android/iOS) — ichki route sinxron pop.
  /// `true` qaytarsa event qayta ishlandi.
  static bool handleSystemBack() {
    final nav = NavigationService.navigatorKey.currentState;
    MySafarSdk.logBack('handleSystemBack(canPop: ${nav?.canPop()})');
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

  /// SDK ichki stack → pop; root → non-home tab'dan Main yoki host'ga chiqish.
  static void handleBack() {
    if (handleSystemBack()) return;
    handleRootBack();
  }

  /// Root (stack bo'sh): non-home tab → Main; Main → host.
  static void handleRootBack() {
    MySafarSdk.logBack(
      'handleRootBack(embedded: ${MySafarSdk.isEmbedded}, '
      'locked: $_rootBackLocked, '
      'tab: ${BottomNavBarPage.currentTabIndex.value})',
    );
    if (!MySafarSdk.isEmbedded) return;
    if (_rootBackLocked) return;

    _rootBackLocked = true;
    Future<void>.delayed(rootBackLock, () {
      _rootBackLocked = false;
    });

    if (BottomNavBarPage.currentTabIndex.value != 0) {
      BottomNavBarPage.switchTo(0);
      return;
    }

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
