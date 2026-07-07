import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;

/// Global navigator key to allow navigation from services (e.g., notification taps).
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Hozirgi (eng yuqoridagi) ekran route nomi.
  ///
  /// Xatolik eventlarida foydalanuvchi qaysi ekranda turganini aniqlash uchun
  /// ishlatiladi. [AppRouteObserver] orqali avtomatik yangilanib turadi.
  static String currentRouteName = 'unknown';

  /// Navigatsiya o'zgarishlarini kuzatib, [currentRouteName] ni yangilab turadi.
  /// [MaterialApp.navigatorObservers] ga qo'shilishi kerak.
  static final AppRouteObserver routeObserver = AppRouteObserver();
}

/// Har bir push/pop/replace da eng yuqoridagi ekran nomini [NavigationService]
/// ga yozib boradi. Bu Dio interceptor/RequestConfig qatlamida xatolik yuz
/// berganda qaysi ekranda bo'lganini bilish imkonini beradi.
class AppRouteObserver extends NavigatorObserver {
  void _update(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty) {
      // Ekran o'zgargandagina screen_view yuboramiz (takrorni oldini olish).
      if (name != NavigationService.currentRouteName) {
        AnalyticsService().trackScreenView(name);
      }
      NavigationService.currentRouteName = name;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Pop bo'lganda ostidagi (endi faollashgan) ekranga qaytamiz.
    _update(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _update(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
