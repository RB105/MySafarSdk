import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart'
    show SdkLocalization;
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
import 'package:provider/provider.dart';

/// SDK'ning to'liq app rejimi — o'zi `MaterialApp` quradi. Example app va
/// keyinchalik MySafar app'ning o'zi shundan foydalanadi.
///
/// `MySafarSdk.init` chaqirilgan bo'lishi shart.
class MySafarApp extends StatelessWidget {
  const MySafarApp({super.key, this.initialRoute});

  /// Boshlang'ich route. Berilmasa asosiy sahifa.
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return _MySafarShell(
      builder: (context) => _sdkMaterialApp(
        context,
        initialRoute: initialRoute ?? BottomNavBarPage.routeName,
      ),
    );
  }
}

/// SDK'ning embed rejimi — host app (masalan Unired) buni oddiy route sifatida
/// push qiladi. Ichkarida o'z Navigator/theme/lokalizatsiyasiga ega nested
/// `MaterialApp` quriladi; Android back tugmasi avval ichki stack'ni yechadi,
/// ichki stack tugagach host'ga qaytadi.
///
/// Izolyatsiya kafolati: SDK host'ning theme'i, lokalizatsiyasi, MediaQuery
/// sozlamalari yoki storage'iga TEGMAYDI va ularga bog'lanmaydi — hammasi
/// nested MaterialApp ichida, SDK'ning o'z resurslari bilan ishlaydi.
///
/// Cheklov: global `NavigationService.navigatorKey` tufayli bir vaqtda faqat
/// BITTA `MySafarEmbed`/`MySafarApp` instance'i mavjud bo'lishi mumkin.
class MySafarEmbed extends StatefulWidget {
  const MySafarEmbed({super.key, this.initialRoute, this.phoneNumber});

  final String? initialRoute;

  /// Berilsa, ekran ochilishidan oldin foydalanuvchi shu raqam bilan MySafar
  /// backend'ida jim ro'yxatdan o'tkaziladi ([MySafarSdk.ensureRegistered]).
  /// Bir marta bajariladi; raqam o'zgargan bo'lsa qayta ro'yxatdan o'tadi.
  /// Ro'yxat muvaffaqiyatsiz bo'lsa ham ekran ochiladi (mehmon rejimi).
  final String? phoneNumber;

  @override
  State<MySafarEmbed> createState() => _MySafarEmbedState();
}

class _MySafarEmbedState extends State<MySafarEmbed> {
  late final Future<void> _ready = widget.phoneNumber == null
      ? Future<void>.value()
      : MySafarSdk.ensureRegistered(widget.phoneNumber!);

  @override
  void initState() {
    super.initState();
    // Home ekranidagi "orqaga" tugmasi shu orqali host route'ini yopadi.
    MySafarSdk.attachEmbedExit(() {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    MySafarSdk.detachEmbedExit();
    super.dispose();
  }

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
      child: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            // Jim ro'yxatdan o'tish ketmoqda — host theme'iga bog'lanmagan
            // neytral yuklanish ekrani.
            return const ColoredBox(
              color: Color(0xFFF5F6FA),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3E5788)),
              ),
            );
          }
          return _MySafarShell(
            builder: (context) => _sdkMaterialApp(
              context,
              initialRoute: widget.initialRoute ?? BottomNavBarPage.routeName,
            ),
          );
        },
      ),
    );
  }
}

/// SDK'ning yagona MaterialApp fabrikasi — theme, router va lokalizatsiya
/// to'liq SDK'niki. easy_localization YO'Q: `SdkLocalization` global holatga
/// tegmaydi, shuning uchun host app'ning tarjimalari buzilmaydi.
Widget _sdkMaterialApp(BuildContext context, {required String initialRoute}) {
  return MaterialApp(
    navigatorKey: NavigationService.navigatorKey,
    navigatorObservers: [NavigationService.routeObserver],
    locale: SdkLocalization.locale,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      ...tgFallbackDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: SdkLocalization.supportedLocales,
    onGenerateRoute: RouterGenerator.router.onGenerate,
    theme: ProjectTheme.light,
    darkTheme: ProjectTheme.dark,
    themeMode: context.select<ThemeNotifier, ThemeMode>(
        (notifier) => notifier.themeMode),
    debugShowCheckedModeBanner: false,
    initialRoute: initialRoute,
  );
}

/// Umumiy qobiq: SDK til notifier'i + provider'lar (theme, valyuta).
/// [builder] provider'lar OSTIDAGI context bilan chaqiriladi; til o'zgarsa
/// butun SDK subtree qayta quriladi.
class _MySafarShell extends StatelessWidget {
  const _MySafarShell({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: SdkLocalization.localeNotifier,
      builder: (context, _, __) => MultiProvider(
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
