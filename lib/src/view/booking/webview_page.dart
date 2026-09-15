import 'dart:convert' show jsonDecode;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/widgets/edge_swipe_back.dart';
import 'package:mysafar_sdk/src/core/widgets/toast_widget.dart';
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

  const WebViewScreen({super.key, required this.url});

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
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

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
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            _log('page finished: $url');
            _injectCompatShim();
            _injectDebugHooks();
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            _log('resource error ${error.errorCode} ${error.errorType} '
                '(${error.isForMainFrame == true ? 'main' : 'sub'}): '
                '${error.description} — ${error.url}');
            _openAppSchemeFromError(error);
            setState(() {
              isLoading = false;
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
      "Ilova o'rnatilmagan yoki ochib bo'lmadi",
      context: context,
    );
  }

  /// Tizim back va chetdan swipe: avval WebView ichida ortga, oxirida
  /// sahifani yopadi. (AppBar'dagi tugma esa sahifani darhol yopadi.)
  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // AppBar'dagi orqaga tugmasi to'lov sahifasini darhol yopadi
          // (tizim back / chetdan swipe esa avval WebView tarixida ortga).
          leading: BackButton(onPressed: () => Navigator.of(context).pop()),
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
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ));
  }
}
