import 'package:flutter/foundation.dart'
    show FlutterExceptionHandler, kDebugMode;
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
  // Ro'yxatdan o'tish 10s dan oshsa kutmaymiz — mehmon rejimida ochamiz
  // (aks holda sekin tarmoqda foydalanuvchi bo'sh ekranga qarab qoladi).
  late final Future<void> _ready = widget.phoneNumber == null
      ? Future<void>.value()
      : MySafarSdk.ensureRegistered(widget.phoneNumber!)
          .timeout(const Duration(seconds: 10), onTimeout: () => false);

  // Debug'da qora ekran o'rniga xatoni ekranda ko'rsatamiz — embed subtree'da
  // yiqilgan har qanday exception shu yerda ushlanadi.
  FlutterErrorDetails? _caughtError;
  FlutterExceptionHandler? _prevOnError;

  @override
  void initState() {
    super.initState();
    // Home ekranidagi "orqaga" tugmasi shu orqali host route'ini yopadi.
    MySafarSdk.attachEmbedExit(() {
      if (mounted) Navigator.of(context).pop();
    });
    if (kDebugMode) {
      _prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        _prevOnError?.call(details);
        if (mounted && _caughtError == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _caughtError = details);
          });
        }
      };
    }
  }

  @override
  void dispose() {
    if (kDebugMode && _prevOnError != null) {
      FlutterError.onError = _prevOnError;
    }
    MySafarSdk.detachEmbedExit();
    super.dispose();
  }

  Widget _debugErrorScreen(FlutterErrorDetails details) {
    return ColoredBox(
      color: const Color(0xFFB00020),
      child: SafeArea(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'MySafar SDK xatosi (faqat debug\'da ko\'rinadi):\n\n'
              '${details.exceptionAsString()}\n\n'
              '${details.stack ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && _caughtError != null) {
      return _debugErrorScreen(_caughtError!);
    }
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
    // MUHIM: default onGenerateInitialRoutes '/bottom_nav_bar'ni ['/','/bottom_nav_bar']
    // zanjiriga bo'ladi; router'dagi '/' case (telegram-auth qaytishi uchun)
    // postFrame'da pop qilib butun stack'ni bo'shatib qo'yardi — embed qora
    // ekran bo'lib qolardi. Faqat so'ralgan route'ning o'zini quramiz.
    onGenerateInitialRoutes: (String route) =>
        [RouterGenerator.router.onGenerate(RouteSettings(name: route))],
    theme: ProjectTheme.light,
    darkTheme: ProjectTheme.dark,
    // watch — ThemeMode.system bo'lganda terminal `b` (platform brightness)
    // o'zgarganda isDark ham yangilanadi va MaterialApp qayta chiziladi.
    themeMode: context.watch<ThemeNotifier>().themeMode,
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
          ChangeNotifierProvider<ThemeNotifier>(
            create: (_) =>
                ThemeNotifier(initialMode: MySafarSdk.config.themeMode),
          ),
          ChangeNotifierProvider<CurrencyProvider>(
              create: (_) => CurrencyProvider()),
        ],
        child: Builder(builder: builder),
      ),
    );
  }
}
