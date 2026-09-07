import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/widgets/edge_swipe_back.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart';

/// Embed rejimida tizim back (Android), predictive back va iOS chetdan swipe
/// UI orqaga tugmasi bilan bir xil ishlaydi:
/// 1) SDK ichki stack → pop
/// 2) non-home tab (profil / buyurtmalar / yo'nalishlar) → Main
/// 3) Main → ikki marta orqaga → [MySafarSdk.exitEmbed]
///
/// [MaterialApp.builder] ichida turishi shart — nested navigator back eventini
/// host route'iga o'tkazib yubormasdan oldin ushlaydi.
class SdkEmbedBackHandler extends StatelessWidget {
  const SdkEmbedBackHandler({super.key, required this.child});

  final Widget child;

  /// `nav.pop()` chaqiruvi ichidagi qayta kiruvchi pop route'larini ajratish.
  static int _internalPopDepth = 0;

  static bool get isHandlingInternalPop => _internalPopDepth > 0;

  /// Double-back oynasi (Main → host).
  static const Duration doubleBackWindow = Duration(seconds: 2);

  /// PopScope + didPopRoute bir gesture'da ikki marta kelishini yutish.
  /// Foydalanuvchi ikkinchi "chiqish" bosishi odatda undan kechroq.
  static const Duration rootBackLock = Duration(milliseconds: 400);

  static DateTime? _lastBackAt;
  static bool _rootBackLocked = false;

  /// Tab almashtirilganda yoki testda double-back holatini tozalash.
  static void resetDoubleBack() {
    _lastBackAt = null;
    _rootBackLocked = false;
  }

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

  /// SDK ichki stack → pop; root → tab/home yoki double-back exit.
  static void handleBack() {
    if (handleSystemBack()) return;
    handleRootBack();
  }

  /// Root (stack bo'sh): non-home tab → Main; Main → 2× back → host.
  static void handleRootBack() {
    if (!MySafarSdk.isEmbedded) return;
    if (_rootBackLocked) return;

    _rootBackLocked = true;
    Future<void>.delayed(rootBackLock, () {
      _rootBackLocked = false;
    });

    final now = DateTime.now();
    final tab = BottomNavBarPage.currentTabIndex.value;
    if (tab != 0) {
      _lastBackAt = null;
      BottomNavBarPage.switchTo(0);
      return;
    }

    if (_lastBackAt != null &&
        now.difference(_lastBackAt!) < doubleBackWindow) {
      _lastBackAt = null;
      MySafarSdk.exitEmbed();
      return;
    }

    _lastBackAt = now;
    try {
      showToastMessage(
        'press_again_to_exit'.tr(
          defaultValue: 'Chiqish uchun yana bosing',
        ),
      );
    } catch (_) {
      // Test / toast plugin yo'q muhit — silent.
    }
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
