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

  /// SDK qayta ochilganda (embed/app) chaqiriladi: oldingi sessiyadagi oxirgi
  /// ekran nomi saqlanib qolgani uchun qayta kirishdagi birinchi screen_view
  /// (masalan `tab_home`) "takror" deb tashlanardi (№97).
  static void resetScreenTracking() => currentRouteName = 'unknown';

  /// Navigatsiya o'zgarishlarini kuzatib, [currentRouteName] ni yangilab turadi.
  /// [MaterialApp.navigatorObservers] ga qo'shilishi kerak.
  static final AppRouteObserver routeObserver = AppRouteObserver();

  /// Embed rejimida iOS chetdan swipe faqat SDK root'ida yoqilishi uchun
  /// ichki stack o'zgarishlarini bildiradi.
  static final ValueNotifier<int> embedStackGeneration = ValueNotifier(0);

  static final EmbedStackNavigatorObserver embedStackObserver =
      EmbedStackNavigatorObserver();

  /// Nomsiz (`MaterialPageRoute(builder: ...)`) route'larga sahifa o'zi bergan
  /// ekran nomi — pop bo'lib shu sahifaga qaytilganda ham to'g'ri nom chiqadi.
  static final Expando<String> _screenNames = Expando<String>('sdkScreen');

  /// Bir route ichida ekranlari almashadigan sahifalar (navbar tablari) uchun
  /// route nomi → joriy ekran nomi. Shunda shu route'ga push/pop bo'lganda
  /// `/bottom_nav_bar` emas, aynan ko'rinib turgan tab (`tab_orders`) yoziladi.
  static final Map<String, String Function()> _screenAliases = {};

  /// [routeName] uchun dinamik ekran nomini ro'yxatdan o'tkazadi (router
  /// route'ni qurishdan oldin chaqiradi; takror chaqirish zararsiz).
  static void registerScreenAlias(
      String routeName, String Function() resolver) {
    _screenAliases[routeName] = resolver;
  }

  /// [route] nomi dinamik (alias) bo'lsa `true`.
  static bool hasScreenAlias(Route<dynamic>? route) =>
      _screenAliases.containsKey(route?.settings.name);

  /// [route] uchun ekran nomi: `settings.name` (yoki uning aliasi) yoki
  /// [markScreen] bergani.
  static String? screenNameOf(Route<dynamic>? route) {
    if (route == null) return null;
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      final alias = _screenAliases[name];
      if (alias == null) return name;
      try {
        final resolved = alias();
        return resolved.isEmpty ? name : resolved;
      } catch (_) {
        return name;
      }
    }
    return _screenNames[route];
  }

  /// Nomsiz ochiladigan sahifalar (va navbar tablari) uchun screen_view:
  /// [name] ni joriy ekran qilib belgilaydi (takror bo'lsa yubormaydi).
  /// [route] berilsa nom unga biriktiriladi; route o'z nomiga ega bo'lsa
  /// observer allaqachon yozgan — hech narsa qilinmaydi.
  static void markScreen(String name, {Route<dynamic>? route}) {
    if (name.isEmpty) return;
    if (route != null) {
      final own = route.settings.name;
      if (own != null && own.isNotEmpty) return;
      _screenNames[route] = name;
      if (!route.isCurrent) return;
    }
    if (name != currentRouteName) {
      AnalyticsService().trackScreenView(name);
    }
    currentRouteName = name;
  }
}

/// Har bir push/pop/replace da eng yuqoridagi ekran nomini [NavigationService]
/// ga yozib boradi. Bu Dio interceptor/RequestConfig qatlamida xatolik yuz
/// berganda qaysi ekranda bo'lganini bilish imkonini beradi.
///
/// screen_view (№19) faqat sahifa route'lari ([PageRoute]) uchun — dialog va
/// bottom sheet'lar ekran hisoblanmaydi (ulardan qaytishda ham takror yo'q:
/// ostidagi sahifa nomi [NavigationService.currentRouteName] bilan bir xil).
/// Takrorlanmaslik: nom o'zgarganidagina yuboriladi, [NavigationService
/// .markScreen] va navbar tablari ham shu [currentRouteName] orqali o'tadi.
class AppRouteObserver extends NavigatorObserver {
  void _update(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    // Alias'li route (navbar): tab indeksi sahifa initState'ida o'rnatiladi —
    // nomni birinchi kadrdan keyin, route hali tepada bo'lsa o'qiymiz.
    if (NavigationService.hasScreenAlias(route)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isCurrent) _report(route);
      });
      return;
    }
    _report(route);
  }

  void _report(Route<dynamic> route) {
    final name = NavigationService.screenNameOf(route);
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
    if (route is PageRoute) {
      // Voronka (passenger_form_started/completed) — faqat oldinga o'tishda.
      AnalyticsService().trackRouteFunnel(
          route.settings.name, previousRoute?.settings.name);
    }
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

/// Embed back handler iOS swipe uchun stack chuqurligini kuzatadi.
class EmbedStackNavigatorObserver extends NavigatorObserver {
  void _notify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService.embedStackGeneration.value++;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notify();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notify();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notify();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _notify();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
