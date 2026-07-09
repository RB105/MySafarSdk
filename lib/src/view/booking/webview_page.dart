import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/widgets/edge_swipe_back.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
  static const routName="/webView";
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController(
      onPermissionRequest: (WebViewPermissionRequest request) {
        request.grant();
      },
    );

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            if (_isCustomScheme(url)) {
              await _launchExternalApp(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _isCustomScheme(String url) {
    final uri = Uri.parse(url);
    return uri.scheme != 'http' && uri.scheme != 'https';
  }

  /// http(s) bo'lmagan sxema — to'lov ilovasini (Click, Payme, bank ilovalari)
  /// tashqarida ochishga urinadi.
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ilova o'rnatilmagan yoki ochib bo'lmadi"),
      ),
    );
  }

  /// Ortga qaytish logikasi — back tugmasi, system back va chetdan swipe
  /// uchun bir xil: avval webview ichida ortga, oxirida sahifani yopadi.
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

        bottom: isLoading
            ? const PreferredSize(
                preferredSize: Size(double.infinity, 3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body:SafeArea(
        bottom: true,
        child:  PopScope(
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
