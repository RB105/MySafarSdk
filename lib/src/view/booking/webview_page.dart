import 'dart:convert' show jsonDecode;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/widgets/edge_swipe_back.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/view/booking/support/webview_compat.dart';
import 'package:mysafar_sdk/src/view/booking/support/webview_debug.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart' show launchUrlString;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'
    show AndroidWebViewController, AndroidWebViewCookieManager;
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'
    show WebKitWebViewControllerCreationParams, WebKitWebViewPlatform;

class WebViewScreen extends StatefulWidget {
  final String url;

  /// To'lov sahifasi: yopishdan oldin tasdiqlash so'raladi (to'lov o'rtasida
  /// tasodifan chiqib ketmaslik uchun). Oddiy sahifalarda (oferta) — yo'q.
  final bool confirmClose;

  const WebViewScreen({super.key, required this.url, this.confirmClose = false});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
  static const routName = "/webView";

  /// WebView ichida qolishi kerak bo'lgan sxemalar. `about:blank`,
  /// `about:srcdoc`, `data:`, `blob:`, `javascript:` — to'lov/3DS sahifalari
  /// yashirin iframe'larda ishlatadi (iOS'da navigatsiya delegati iframe'lar
  /// uchun ham chaqiriladi); ularni bloklash 3DS tekshiruvini buzadi.
  static const Set<String> _inWebViewSchemes = {
    'http',
    'https',
    'about',
    'data',
    'blob',
    'javascript',
  };

  /// [url] to'lov ilovasining sxemasimi (Click, Payme, bank ilovalari,
  /// `intent:` va h.k.) — WebView'da emas, tashqi ilovada ochiladi.
  static bool opensExternally(String url) {
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase() ?? '';
    return scheme.isNotEmpty && !_inWebViewSchemes.contains(scheme);
  }

  /// Android `WebViewClient.ERROR_*` kodlari: host topilmadi (-2), ulanish
  /// (-6), I/O (-7), taymaut (-8).
  static const Set<int> _androidNetworkCodes = {-2, -6, -7, -8};

  /// iOS `NSURLError*`: taymaut (-1001), host topilmadi (-1003), ulanib
  /// bo'lmadi (-1004), aloqa uzildi (-1005), DNS (-1006), internet yo'q
  /// (-1009), xalqaro rouming o'chiq (-1018), ma'lumot uzatish o'chiq (-1020).
  static const Set<int> _iosNetworkCodes = {
    -1001,
    -1003,
    -1004,
    -1005,
    -1006,
    -1009,
    -1018,
    -1020,
  };

  /// Asosiy sahifa internet/ulanish sababli yuklanmadimi (№48) — shunda
  /// tizimning "sahifa mavjud emas" ekrani o'rniga o'z xato ko'rinishimiz
  /// ("Qayta yuklash" bilan) chiqadi. Iframe xatolari, ilova sxemalari va
  /// bekor qilingan navigatsiya (iOS -999) hisobga olinmaydi.
  static bool isConnectionError({
    required int errorCode,
    required bool? isForMainFrame,
    String? url,
    WebResourceErrorType? errorType,
  }) {
    if (isForMainFrame != true) return false;
    if (url != null && opensExternally(url)) return false;
    switch (errorType) {
      case WebResourceErrorType.hostLookup:
      case WebResourceErrorType.connect:
      case WebResourceErrorType.timeout:
      case WebResourceErrorType.io:
        return true;
      default:
        break;
    }
    return _androidNetworkCodes.contains(errorCode) ||
        _iosNetworkCodes.contains(errorCode);
  }
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  /// Yopishni tasdiqlash dialogi ochiq — ikkinchisi ochilmasin.
  bool _closeDialogOpen = false;

  /// Asosiy sahifa internet sababli yuklanmadi — WebView ustida o'z xato
  /// ko'rinishimiz ("Qayta yuklash") turadi (№48).
  bool _connectionError = false;

  /// Android: navigatsiya delegati o'rnatilmaydi — WebView sahifalarni Chrome
  /// kabi o'zi ochadi. (`onNavigationRequest` berilsa plagin har bir asosiy
  /// o'tishni bekor qilib, URL'ni Dart `Uri` orqali `loadUrl` bilan qayta
  /// yuklaydi: URL qayta yoziladi, redirect/Referer buziladi.) Ilova
  /// sxemalari `onWebResourceError` (unsupported scheme) orqali ochiladi.
  late final bool _nativeNavigation;

  /// Debug: WebView ekrani har ochilganda +1 — bitta to'lov URL'i ikki marta
  /// ochilyaptimi, shuni ko'rish uchun.
  static int _debugOpenCount = 0;

  @override
  void initState() {
    super.initState();

    // iOS: skript orqali yangi oyna ochishga ruxsat (Android plagini buni
    // sukut bo'yicha yoqadi) — 3DS sahifalari `window.open` ishlatadi.
    final PlatformWebViewControllerCreationParams params =
        WebViewPlatform.instance is WebKitWebViewPlatform
            ? WebKitWebViewControllerCreationParams(
                allowsInlineMediaPlayback: true,
                javaScriptCanOpenWindowsAutomatically: true,
              )
            : const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (WebViewPermissionRequest request) {
        request.grant();
      },
    );

    _nativeNavigation = _controller.platform is AndroidWebViewController;

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _nativeNavigation ? null : _onNavigationRequest,
          onUrlChange: (UrlChange change) {
            _log('url change: ${change.url}');
          },
          onPageStarted: (String url) {
            _log('page started: $url');
            _injectCompatShim();
            if (!mounted) return;
            setState(() {
              isLoading = true;
              _connectionError = false;
            });
          },
          onPageFinished: (String url) {
            _log('page finished: $url');
            _injectCompatShim();
            _injectDebugHooks();
            if (!mounted) return;
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            _log('resource error ${error.errorCode} ${error.errorType} '
                '(${error.isForMainFrame == true ? 'main' : 'sub'}): '
                '${error.description} — ${error.url}');
            _openAppSchemeFromError(error);
            if (!mounted) return;
            final connectionError = WebViewScreen.isConnectionError(
              errorCode: error.errorCode,
              isForMainFrame: error.isForMainFrame,
              url: error.url,
              errorType: error.errorType,
            );
            setState(() {
              isLoading = false;
              if (connectionError) _connectionError = true;
            });
          },
          onHttpError: (HttpResponseError error) {
            _log('http ${error.response?.statusCode}: ${error.request?.uri} '
                'headers=${error.response?.headers}');
          },
        ),
      );
    _setUpDebugging();
    _prepareAndLoad();
  }

  /// iOS: ilova sxemalari (Payme, Click, bank ilovalari) tashqarida ochiladi;
  /// `about:` / `data:` kabi iframe sxemalari WebView ichida qoladi.
  Future<NavigationDecision> _onNavigationRequest(
      NavigationRequest request) async {
    final url = request.url;
    _log('navigate ${request.isMainFrame ? 'main' : 'frame'}: $url');
    if (WebViewScreen.opensExternally(url)) {
      _log('-> tashqi ilova');
      await _launchExternalApp(url);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  /// Android ([_nativeNavigation]): asosiy sahifa ilova sxemasiga o'tganda
  /// WebView "unsupported scheme" xatosini beradi — ilovani tashqarida
  /// ochib, xato sahifasidan ortga qaytamiz.
  Future<void> _openAppSchemeFromError(WebResourceError error) async {
    if (!_nativeNavigation || error.isForMainFrame != true) return;
    final url = error.url ?? '';
    if (!WebViewScreen.opensExternally(url)) return;
    _log('-> tashqi ilova (android): $url');
    await _launchExternalApp(url);
    if (mounted && await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  /// Brauzer bilan bir xil sharoit tayyorlab, to'lov sahifasini yuklaydi.
  Future<void> _prepareAndLoad() async {
    await _enableThirdPartyCookies();
    await _applyBrowserUserAgent();
    if (!mounted) return;
    await _loadInitialUrl();
  }

  /// "Qayta yuklash": har doim boshlang'ich to'lov URL'i (GET) qayta
  /// ochiladi (№65). `reload()` POST bilan ochilgan bank/3DS sahifasini
  /// qayta yuborardi (Android) — takroriy to'lov urinishi yoki "sessiya
  /// tugadi". To'lov sahifasi joriy holatni o'zi ko'rsatadi.
  Future<void> _retryAfterConnectionError() async {
    setState(() {
      _connectionError = false;
      isLoading = true;
    });
    try {
      _log('qayta yuklash: boshlang\'ich URL');
      await _loadInitialUrl();
    } catch (e) {
      _log('qayta yuklash xatosi: $e');
      if (mounted) {
        setState(() {
          _connectionError = true;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInitialUrl() async {
    final url = widget.url;
    // Dart Uri URL'ni qayta yozadigan bo'lsa — xom satrni brauzerdagidek
    // yuklaymiz (iOS ham, Android ham).
    if (WebViewCompat.changesWhenParsed(url)) {
      _log('load: xom URL (Dart Uri o\'zgartirardi)');
      await _controller.loadHtmlString(WebViewCompat.rawRedirectHtml(url));
      return;
    }
    await _controller.loadRequest(Uri.parse(url));
  }

  /// iOS — Safari, Android — Chrome User-Agent'i (WebView belgilarisiz).
  Future<void> _applyBrowserUserAgent() async {
    try {
      String? userAgent = WebViewCompat.iosSafariUserAgent();
      if (userAgent == null && _nativeNavigation) {
        userAgent = WebViewCompat.chromeLikeUserAgent(
          await _controller.getUserAgent(),
        );
      }
      if (userAgent == null) return;
      await _controller.setUserAgent(userAgent);
      _log('userAgent -> $userAgent');
    } catch (_) {
      // User-Agent o'rnatilmasa ham sahifa ochilaversin.
    }
  }

  /// Yangi oyna so'rovlarini joriy oynaga yo'naltiruvchi shim (har sahifada).
  void _injectCompatShim() {
    _controller
        .runJavaScript(WebViewCompat.popupShimScript)
        .catchError((Object e) => _log('compat shim kiritilmadi: $e'));
  }

  void _log(String message) => WebViewDebug.log(message);

  /// Debug: URL normalizatsiyasi, platforma, User-Agent, JS console va
  /// sahifadagi hook'lar (form / fetch / XHR / window.open / JS xatolari).
  void _setUpDebugging() {
    if (!WebViewDebug.enabled) return;
    _debugOpenCount++;
    _log('==== WebView ochildi #$_debugOpenCount '
        '(${Platform.operatingSystem} ${Platform.operatingSystemVersion}) ====');
    WebViewDebug.logUrlNormalization(widget.url);
    _controller
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        _log('console.${message.level.name}: ${message.message}');
      })
      ..addJavaScriptChannel(
        WebViewDebug.channelName,
        onMessageReceived: (JavaScriptMessage message) {
          _logPageEvent(message.message);
        },
      );
    _controller.getUserAgent().then((ua) => _log('native userAgent: $ua'));
  }

  void _injectDebugHooks() {
    if (!WebViewDebug.enabled) return;
    _controller
        .runJavaScript(WebViewDebug.injectedScript)
        .catchError((Object e) => _log('hook kiritilmadi: $e'));
  }

  void _logPageEvent(String raw) {
    try {
      final event = jsonDecode(raw) as Map<String, dynamic>;
      final type = event['type'];
      final data = event['data'];
      if (type == 'snapshot' && data is Map) {
        _log('-- sahifa (${data['reason']}) ${data['href']}');
        _log('   title="${data['title']}" referrer="${data['referrer']}" '
            'ready=${data['readyState']} cookies=${data['cookieCount']}');
        _log('   js userAgent: ${data['userAgent']}');
        for (final form in (data['forms'] as List? ?? const [])) {
          _log('   form: $form');
        }
        for (final frame in (data['iframes'] as List? ?? const [])) {
          _log('   iframe: $frame');
        }
        _log('   text: ${data['text']}');
        return;
      }
      _log('js $type: $data');
    } catch (_) {
      _log('js: $raw');
    }
  }

  /// Debug menyu: bir xil URL'ni turli yo'l bilan ochib, qaysi farq
  /// muammoga sabab ekanini aniqlash.
  Future<void> _onDebugAction(String action) async {
    final raw = widget.url;
    switch (action) {
      case 'snapshot':
        _controller
            .runJavaScript(
                "window.__mysafarDebugSnapshot && window.__mysafarDebugSnapshot('manual')")
            .catchError((Object e) => _log('snapshot xatosi: $e'));
      case 'webview-raw':
        _log('>> WebView: xom URL (JS redirect, Dart Uri\'siz)');
        await _controller.loadHtmlString(WebViewCompat.rawRedirectHtml(raw));
      case 'webview-dart':
        _log('>> WebView: Dart Uri.parse bilan qayta yuklash');
        await _controller.loadRequest(Uri.parse(raw));
      case 'browser-raw':
        _log('>> Brauzer: xom URL (launchUrlString)');
        await launchUrlString(raw, mode: LaunchMode.externalApplication);
      case 'browser-dart':
        _log('>> Brauzer: Dart Uri.parse (launchUrl)');
        await launchUrl(Uri.parse(raw), mode: LaunchMode.externalApplication);
    }
  }

  /// Android WebView uchinchi tomon cookie'larini sukut bo'yicha rad etadi
  /// (Chrome esa ruxsat beradi). To'lov shlyuzi ichidagi bank ACS/OTP
  /// iframe'i boshqa domendan ochiladi va sessiya cookie'siz ishlamaydi —
  /// shuning uchun sahifa yuklanishidan oldin yoqamiz. iOS'da hech narsa
  /// qilinmaydi.
  Future<void> _enableThirdPartyCookies() async {
    final platformController = _controller.platform;
    if (platformController is! AndroidWebViewController) return;
    try {
      final cookieManager = WebViewCookieManager().platform;
      if (cookieManager is AndroidWebViewCookieManager) {
        await cookieManager.setAcceptThirdPartyCookies(
          platformController,
          true,
        );
        _log('android third-party cookies: on');
      }
    } catch (_) {
      // Cookie sozlanmasa ham sahifa ochilaversin.
    }
  }

  /// To'lov ilovasi sxemasi ([WebViewScreen.opensExternally]) — ilovani
  /// (Click, Payme, bank ilovalari) tashqarida ochishga urinadi.
  ///
  /// `canLaunchUrl` ATAYIN ishlatilmaydi: Android 11+ da u package-visibility
  /// cheklovi tufayli ilova o'rnatilgan bo'lsa ham `false` qaytarishi mumkin
  /// ("ilova topilmadi"). `launchUrl` esa to'g'ridan-to'g'ri `startActivity`
  /// chaqiradi — bu cheklovga tushmaydi va ilova haqiqatan o'rnatilmagan
  /// bo'lsagina `false`/xatolik qaytaradi.
  Future<void> _launchExternalApp(String url) async {
    bool launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }
    if (!mounted || launched) return;
    showErrorMessage(
      'app_not_installed_or_failed'.tr(),
      context: context,
    );
  }

  /// Tizim back va chetdan swipe: avval WebView ichida ortga, oxirida
  /// sahifani yopadi. (AppBar'dagi tugma esa tarixsiz, darhol yopishga
  /// o'tadi.)
  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else {
      await _close();
    }
  }

  /// Sahifani yopadi; to'lov sahifasida avval tasdiqlash so'raladi. Yopilgach
  /// to'lov holatini chaqiruvchi sahifa o'zi tekshiradi.
  Future<void> _close() async {
    if (!mounted || _closeDialogOpen) return;
    if (widget.confirmClose) {
      _closeDialogOpen = true;
      final shouldClose = await showSdkAlert<bool>(
        context: context,
        icon: Assets.iconsDialogWarningIcon,
        tone: SdkDialogTone.warning,
        title: 'payment_close_title'.tr(),
        message: 'payment_close_message'.tr(),
        actions: [
          SdkDialogAction(label: 'exit_payment_continue'.tr(), value: false),
          SdkDialogAction(
            label: 'close'.tr(),
            value: true,
            variant: SdkDialogButtonVariant.dangerSoft,
          ),
        ],
      );
      _closeDialogOpen = false;
      if (shouldClose != true || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // AppBar'dagi orqaga tugmasi WebView tarixisiz yopishga o'tadi
          // (to'lov sahifasida — tasdiqlash bilan); tizim back / chetdan
          // swipe esa avval WebView tarixida ortga.
          leading: BackButton(onPressed: _close),
          actions: [
            if (WebViewDebug.enabled)
              PopupMenuButton<String>(
                icon: const Icon(Icons.bug_report_outlined),
                onSelected: _onDebugAction,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'snapshot', child: Text('Sahifa holatini log')),
                  PopupMenuItem(
                      value: 'webview-raw',
                      child: Text('WebView: xom URL (Dart Uri\'siz)')),
                  PopupMenuItem(
                      value: 'webview-dart',
                      child: Text('WebView: Dart Uri bilan')),
                  PopupMenuItem(
                      value: 'browser-raw', child: Text('Brauzer: xom URL')),
                  PopupMenuItem(
                      value: 'browser-dart',
                      child: Text('Brauzer: Dart Uri bilan')),
                ],
              ),
          ],
          bottom: isLoading
              ? const PreferredSize(
                  preferredSize: Size(double.infinity, 3),
                  child: LinearProgressIndicator(minHeight: 3),
                )
              : null,
        ),
        body: SafeArea(
          bottom: true,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, dynamic result) {
              if (didPop) return;
              _handleBack();
            },
            child: EdgeSwipeBack(
              onBack: _handleBack,
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_connectionError)
                    Positioned.fill(
                      child: _WebViewConnectionError(
                        onRetry: _retryAfterConnectionError,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ));
  }
}

/// Internet yo'qligida WebView ustidagi xato ko'rinishi (tizimning
/// "sahifa mavjud emas" ekrani o'rniga) — "Qayta yuklash" tugmasi bilan.
class _WebViewConnectionError extends StatelessWidget {
  const _WebViewConnectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color muted =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
            Colors.grey;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 56, color: muted),
              const SizedBox(height: 16),
              Text(
                'connection_error_title'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'connection_error_message'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text('webview_reload'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
