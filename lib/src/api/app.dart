import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/localization/tg_fallback_localizations.dart';
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/router/router.dart' show RouterGenerator;
import 'package:mysafar_sdk/src/core/styles/theme.dart' show ProjectTheme;
import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart'
    show ThemeNotifier;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/view/navbar/bottom_nav_bar.dart'
    show BottomNavBarPage;
import 'package:mysafar_sdk/src/view/splash/splash_screen.dart'
    show SplashScreen;
import 'package:provider/provider.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

const List<Locale> _supportedLocales = [
  Locale('en'),
  Locale('ru'),
  Locale('uz'),
  Locale('kk'),
  Locale('tg'),
  Locale('tr'),
];

/// SDK'ning to'liq app rejimi — o'zi `MaterialApp` quradi. Example app va
/// keyinchalik MySafar app'ning o'zi shundan foydalanadi.
///
/// `MySafarSdk.init` chaqirilgan bo'lishi shart.
class MySafarApp extends StatelessWidget {
  const MySafarApp({super.key, this.initialRoute, this.showSplash = false});

  /// Boshlang'ich route. Berilmasa: [showSplash] `true` bo'lsa splash/
  /// onboarding oqimi, aks holda to'g'ridan-to'g'ri asosiy sahifa.
  final String? initialRoute;
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    return _MySafarLocalizedShell(
      builder: (context) => MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        navigatorObservers: [NavigationService.routeObserver],
        locale: context.locale,
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          ...tgFallbackDelegates,
          ...context.localizationDelegates,
        ],
        supportedLocales: context.supportedLocales,
        onGenerateRoute: RouterGenerator.router.onGenerate,
        theme: ProjectTheme.light,
        darkTheme: ProjectTheme.dark,
        themeMode: context.select<ThemeNotifier, ThemeMode>(
            (notifier) => notifier.themeMode),
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute ??
            (showSplash ? SplashScreen.routeName : BottomNavBarPage.routeName),
      ),
    );
  }
}

/// SDK'ning embed rejimi — host app (masalan Unired) buni oddiy route sifatida
/// push qiladi. Ichkarida o'z Navigator/theme/lokalizatsiyasiga ega nested
/// `MaterialApp` quriladi; Android back tugmasi avval ichki stack'ni yechadi,
/// ichki stack tugagach host'ga qaytadi.
///
/// Cheklov: global `NavigationService.navigatorKey` tufayli bir vaqtda faqat
/// BITTA `MySafarEmbed`/`MySafarApp` instance'i mavjud bo'lishi mumkin.
class MySafarEmbed extends StatelessWidget {
  const MySafarEmbed({super.key, this.initialRoute});

  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = NavigationService.navigatorKey.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
          return;
        }
        Navigator.of(context).pop();
      },
      child: _MySafarLocalizedShell(
        builder: (context) => MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          navigatorObservers: [NavigationService.routeObserver],
          locale: context.locale,
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            ...tgFallbackDelegates,
            ...context.localizationDelegates,
          ],
          supportedLocales: context.supportedLocales,
          onGenerateRoute: RouterGenerator.router.onGenerate,
          theme: ProjectTheme.light,
          darkTheme: ProjectTheme.dark,
          themeMode: context.select<ThemeNotifier, ThemeMode>(
              (notifier) => notifier.themeMode),
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute ?? BottomNavBarPage.routeName,
        ),
      ),
    );
  }
}

/// Umumiy qobiq: EasyLocalization + provider'lar (theme, valyuta).
/// [builder] EasyLocalization/provider'lar OSTIDAGI context bilan chaqiriladi —
/// `context.locale` va `context.select<ThemeNotifier, ...>` shu yerda ishlaydi.
class _MySafarLocalizedShell extends StatelessWidget {
  const _MySafarLocalizedShell({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final config = MySafarSdk.config;
    return EasyLocalization(
      saveLocale: config.saveLocale,
      startLocale: config.startLocale ??
          Locale(sdkStorage().read('lang') ?? 'uz'),
      supportedLocales: _supportedLocales,
      fallbackLocale: const Locale('uz'),
      path: 'packages/mysafar_sdk/assets/lang',
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider<CurrencyProvider>(
              create: (_) => CurrencyProvider()),
        ],
        child: Builder(builder: builder),
      ),
    );
  }
}
