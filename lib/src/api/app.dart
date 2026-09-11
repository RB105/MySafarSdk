import 'package:flutter/foundation.dart'
    show
        FlutterExceptionHandler,
        TargetPlatform,
        defaultTargetPlatform,
        kDebugMode,
        kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show PredictiveBackEvent, SystemNavigator;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart'
    show SdkLocalization;
import 'package:mysafar_sdk/src/core/localization/tg_fallback_localizations.dart';
import 'package:mysafar_sdk/src/core/router/android_system_back.dart';
import 'package:mysafar_sdk/src/core/router/navigation_service.dart';
import 'package:mysafar_sdk/src/core/router/router.dart' show RouterGenerator;
import 'package:mysafar_sdk/src/core/router/sdk_embed_back_handler.dart';
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
  const MySafarEmbed({
    super.key,
    this.initialRoute,
    this.phoneNumber,
    this.email,
    this.locale,
    this.themeMode,
  });

  final String? initialRoute;

  /// Berilsa, ekran ochilishidan oldin foydalanuvchi shu raqam bilan MySafar
  /// backend'ida jim ro'yxatdan o'tkaziladi ([MySafarSdk.ensureRegistered]).
  /// Bir marta bajariladi; raqam o'zgargan bo'lsa qayta ro'yxatdan o'tadi.
  /// Ro'yxat muvaffaqiyatsiz bo'lsa ham ekran ochiladi (mehmon rejimi).
  final String? phoneNumber;

  /// Host user emaili. [phoneNumber] bilan birga berilsa, register'dan
  /// keyin profilga yoziladi (booking kontakt maydoni uchun). Telefon
  /// bo'lmasa email yolg'iz ishlatilmaydi.
  final String? email;

  /// Host appning joriy tili. Berilsa SDK shu tilda ochiladi (masalan
  /// `Locale('ru')`). Saqlanmaydi — keyingi ochilishda yana host tilini
  /// berish kerak. `null` bo'lsa `MySafarConfig.startLocale` / saqlangan /
  /// default `uz` qoladi. Qo'llab-quvvatlanadi: en, ru, uz, kk, tg, tr.
  final Locale? locale;

  /// Host appning joriy temasi. Berilsa SDK shu rejimda ochiladi:
  /// - [ThemeMode.dark] — faqat qorong'u fon
  /// - [ThemeMode.light] — faqat yorug' fon
  /// - `null` — [MySafarConfig.themeMode], yo'q bo'lsa sistema temasi
  /// Saqlanmaydi — keyingi ochilishda yana host temani berish kerak.
  final ThemeMode? themeMode;

  @override
  State<MySafarEmbed> createState() => _MySafarEmbedState();
}

class _MySafarEmbedState extends State<MySafarEmbed> with WidgetsBindingObserver {
  // ── Android back da'vosi ────────────────────────────────────────────────
  //
  // Android 16 (targetSdk 36) da tizim back'ini FAQAT `OnBackInvokedDispatcher`
  // ga ro'yxatdan o'tgan callback ushlaydi — eski `Activity.onBackPressed()` /
  // `KEYCODE_BACK` fallback'i olib tashlangan. Flutter bu callback'ni faqat
  // `SystemNavigator.setFrameworkHandlesBack(true)` yozilganda ro'yxatdan
  // o'tkazadi; `false` yozilsa darhol o'chiradi. Callback o'chiq bo'lsa tizim
  // back'ni Flutter'ga umuman uzatmay, activity'ni yopadi — foydalanuvchi
  // uchun bu "ilova chiqib ketdi" bo'lib ko'rinadi. Android 15 va pastida esa
  // eski fallback ishlaganligi uchun ayni kod muammosiz ishlaydi.
  //
  // MUHIM cheklov: bu da'vo faqat host `FlutterActivity` bo'lganda ish beradi
  // — Flutter callback'ni faqat o'sha yerda ro'yxatdan o'tkazadi. Host boshqa
  // Activity ishlatsa hech narsa ro'yxatdan o'tmaydi va Dart tomondan buni
  // tuzatib bo'lmaydi; o'sha holat uchun SDK'ning o'z Android moduli bor
  // ([AndroidSystemBack]). Quyidagi da'vo — modul ulanmagan build'lar uchun
  // fallback; u host tomonidan qayta yozilishi mumkin bo'lgani uchun
  // navigatsiya va resume hodisalarida qaytadan yoziladi.
  static bool _claimAndroidBack = false;

  static bool get _androidBackClaimNeeded =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Embed ochiq ekan "back'ni Flutter ushlaydi" da'vosini qayta yozadi.
  /// [_claimAndroidBack] o'chiq bo'lsa (embed yopilgan) hech nima qilmaydi —
  /// host o'z back siyosatiga qaytadi.
  static void _reassertAndroidBackClaim() {
    if (!_claimAndroidBack) return;
    SystemNavigator.setFrameworkHandlesBack(true);
  }

  /// Diagnostika: tizim back'i Flutter'ga yetib keladimi. Bu observer hech
  /// qachon gesture'ni o'zi ushlamaydi — shuning uchun doim `false`.
  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    MySafarSdk.logBack(
      'handleStartBackGesture(button: ${backEvent.isButtonEvent}, '
      'progress: ${backEvent.progress})',
    );
    return false;
  }

  void _startAndroidBackClaim() {
    _claimAndroidBack = true;
    _reassertAndroidBackClaim();
    // SDK'ning o'z Android callback'i — host Activity `FlutterActivity`
    // bo'lmasa yagona ishlaydigan yo'l. Ulanmasa (eski host build'i) yuqoridagi
    // da'vo fallback bo'lib qoladi.
    AndroidSystemBack.enable();
    if (!_androidBackClaimNeeded) return;
    // Host'ning o'z NavigationNotification'i post-frame'da keladi va bizning
    // initState'dagi da'vomizni bosib ketishi mumkin — keyingi frame'da
    // qaytadan yozamiz.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _reassertAndroidBackClaim(),
    );
  }

  void _stopAndroidBackClaim() {
    _claimAndroidBack = false;
    AndroidSystemBack.disable();
  }

  // Til + (ixtiyoriy) jim ro'yxatdan o'tish — UI ochilishidan oldin.
  // Ro'yxat 10s dan oshsa kutmaymiz — mehmon rejimida ochamiz.
  late final Future<void> _ready = _prepare();

  Future<void> _prepare() async {
    final locale = widget.locale;
    if (locale != null) {
      // Host tiliga sync — SDK storage'ga yozilmaydi (save: false).
      await SdkLocalization.setLocale(locale, save: false);
    }
    final phone = widget.phoneNumber;
    if (phone == null) return;
    await MySafarSdk.ensureRegistered(
      phone,
      email: widget.email,
    ).timeout(const Duration(seconds: 10), onTimeout: () => false);
  }

  // Debug'da qora ekran o'rniga xatoni ekranda ko'rsatamiz — embed subtree'da
  // yiqilgan har qanday exception shu yerda ushlanadi.
  FlutterErrorDetails? _caughtError;
  FlutterExceptionHandler? _prevOnError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 3-button back Android 16 da OnBackInvokedCallback orqali keladi.
    // Callback o'chiq bo'lsa tizim appni yopadi (EdgeSwipeBack esa Flutter
    // gesture — shuning uchun chetdan surish ishlardi, tugma ishlamasdi).
    _startAndroidBackClaim();
    // Embed ochilganda faqat portrait — host landscape bo'lsa ham.
    MySafarSdk.lockPortrait();
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
    WidgetsBinding.instance.removeObserver(this);
    _stopAndroidBackClaim();
    if (kDebugMode && _prevOnError != null) {
      FlutterError.onError = _prevOnError;
    }
    MySafarSdk.detachEmbedExit();
    // Host app o'z orientation siyosatiga qaytsin.
    MySafarSdk.restoreOrientations();
    super.dispose();
  }

  /// Activity qayta yaratilganda (`onCreate` saqlangan `frameworkHandlesBack`
  /// ni tiklaydi) yoki host boshqa ekrandan qaytganda da'vo eskirgan bo'lishi
  /// mumkin — resume'da qayta yozamiz.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _reassertAndroidBackClaim();
    }
  }

  /// Android/iOS tizim back — PopScope va [didPopRoute] uchun umumiy handler.
  void _handleEmbedSystemBack() {
    MySafarSdk.logBack('PopScope.onPopInvoked(didPop: false)');
    if (SdkEmbedBackHandler.isHandlingInternalPop) return;
    SdkEmbedBackHandler.handleBack();
  }

  /// Android/iOS tizim back — host navigator o'rniga SDK stack, tab→Main yoki
  /// Main da double-back exit. `true` qaytarsak platforma default pop ishlamaydi.
  @override
  Future<bool> didPopRoute() async {
    MySafarSdk.logBack('didPopRoute');
    if (SdkEmbedBackHandler.isHandlingInternalPop) return false;
    if (SdkEmbedBackHandler.handleSystemBack()) return true;
    if (!MySafarSdk.isEmbedded) return false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SdkEmbedBackHandler.handleRootBack();
    });
    return true;
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
        if (didPop) {
          _stopAndroidBackClaim();
          return;
        }
        _handleEmbedSystemBack();
      },
      child: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            // Jim ro'yxatdan o'tish ketmoqda — host theme'iga bog'lanmagan
            // neytral yuklanish ekrani (embed themeMode berilgan bo'lsa
            // shu rejimga mos).
            final dark = widget.themeMode == ThemeMode.dark ||
                (widget.themeMode == null &&
                    MediaQuery.platformBrightnessOf(context) ==
                        Brightness.dark);
            return ColoredBox(
              color: dark ? const Color(0xFF121212) : const Color(0xFFF5F6FA),
              child: Center(
                child: CircularProgressIndicator(
                  color: dark
                      ? const Color(0xFF8BA3D4)
                      : const Color(0xFF3E5788),
                ),
              ),
            );
          }
          return _MySafarShell(
            themeMode: widget.themeMode,
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

/// Ichki stack bo'sh bo'lsa ham Android'ga "Flutter ushlaydi" deb qayta yozadi.
/// Yutish yetarli emas — host/engine keyin `false` yozib 3-button back'ni
/// back-to-home qilib yuboradi.
bool _embedOnNavigationNotification(NavigationNotification _) {
  _MySafarEmbedState._reassertAndroidBackClaim();
  return true;
}

/// SDK'ning yagona MaterialApp fabrikasi — theme, router va lokalizatsiya
/// to'liq SDK'niki. easy_localization YO'Q: `SdkLocalization` global holatga
/// tegmaydi, shuning uchun host app'ning tarjimalari buzilmaydi.
Widget _sdkMaterialApp(BuildContext context, {required String initialRoute}) {
  final observers = <NavigatorObserver>[
    NavigationService.routeObserver,
    if (MySafarSdk.isEmbedded) NavigationService.embedStackObserver,
  ];

  return MaterialApp(
    navigatorKey: NavigationService.navigatorKey,
    navigatorObservers: observers,
    // Nested MaterialApp default'i inner stack bo'sh bo'lsa
    // setFrameworkHandlesBack(false) yozadi. Android 16 3-button back
    // shu callback o'chiq bo'lsa appni yopadi. Embed ochiq ekan true yozamiz.
    onNavigationNotification: MySafarSdk.isEmbedded
        ? _embedOnNavigationNotification
        : null,
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
    // Nested embed'da MediaQuery.platformBrightness host bilan farq qilishi
    // mumkin — haqiqiy MaterialApp temasi bilan sinxronlashtiramiz.
    builder: (context, child) {
      final brightness = Theme.of(context).brightness;
      final content = MediaQuery(
        data: MediaQuery.of(context).copyWith(platformBrightness: brightness),
        child: child ?? const SizedBox.shrink(),
      );
      return SdkEmbedBackHandler(child: content);
    },
  );
}

/// Umumiy qobiq: SDK til notifier'i + provider'lar (theme, valyuta).
/// [builder] provider'lar OSTIDAGI context bilan chaqiriladi; til o'zgarsa
/// butun SDK subtree qayta quriladi.
class _MySafarShell extends StatelessWidget {
  const _MySafarShell({required this.builder, this.themeMode});

  final WidgetBuilder builder;

  /// Embed host temasi. Berilsa config'dan ustun. `null` bo'lsa
  /// [MySafarConfig.themeMode] / sistema.
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: SdkLocalization.localeNotifier,
      builder: (context, _, __) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeNotifier>(
            create: (_) => ThemeNotifier(
              initialMode: themeMode ?? MySafarSdk.config.themeMode,
            ),
          ),
          ChangeNotifierProvider<CurrencyProvider>(
              create: (_) => CurrencyProvider()),
        ],
        child: Builder(builder: builder),
      ),
    );
  }
}
