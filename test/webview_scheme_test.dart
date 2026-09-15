import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/view/booking/webview_page.dart';

void main() {
  group('WebViewScreen.opensExternally', () {
    test('web va 3DS iframe sxemalari WebView ichida qoladi', () {
      for (final url in [
        'https://ecom.example.uz/pay?id=1',
        'http://example.uz',
        'about:blank',
        'about:srcdoc',
        'data:text/html;base64,PGh0bWw+PC9odG1sPg==',
        'blob:https://acs.bank.uz/6f1c2d3e',
        'javascript:void(0)',
        'HTTPS://EXAMPLE.UZ',
        '',
      ]) {
        expect(WebViewScreen.opensExternally(url), isFalse, reason: url);
      }
    });

    test('to\'lov ilovalari sxemalari tashqarida ochiladi', () {
      for (final url in [
        'payme://checkout?id=1',
        'click://pay',
        'intent://pay#Intent;scheme=uzcard;end',
        'tel:+998555120008',
        'market://details?id=uz.dida.payme',
      ]) {
        expect(WebViewScreen.opensExternally(url), isTrue, reason: url);
      }
    });
  });
}
