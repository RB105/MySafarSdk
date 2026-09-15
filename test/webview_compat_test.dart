import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/view/booking/support/webview_compat.dart';

void main() {
  test('Dart Uri URL\'ni qayta yozishini aniqlaydi', () {
    expect(WebViewCompat.changesWhenParsed('https://pay.uz/ecom?id=1&s=ab%2B'),
        isFalse);
    expect(
        WebViewCompat.changesWhenParsed('https://pay.uz/ecom?x=a|b'), isTrue);
    expect(
        WebViewCompat.changesWhenParsed('https://pay.uz/ecom?q=%7e'), isTrue);
    expect(WebViewCompat.changesWhenParsed('https://pay.uz/e?d=a b'), isTrue);
  });

  test('xom URL redirect HTML xavfsiz escape qilinadi', () {
    final html = WebViewCompat.rawRedirectHtml(
        'https://pay.uz/e?x=a|b&q="</script><script>alert(1)</script>');
    expect(
        html, contains(r'location.replace("https://pay.uz/e?x=a|b\u0026q=\"'));
    expect('</script>'.allMatches(html).length, 1);
    expect(html, isNot(contains('<script>alert')));
  });

  test('Android WebView UA -> Chrome UA', () {
    const webView =
        'Mozilla/5.0 (Linux; Android 14; Pixel 7 Build/UQ1A.240205.004; wv) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 '
        'Chrome/126.0.6478.71 Mobile Safari/537.36';
    expect(
      WebViewCompat.chromeLikeUserAgent(webView),
      'Mozilla/5.0 (Linux; Android 14; Pixel 7 Build/UQ1A.240205.004) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/126.0.6478.71 Mobile Safari/537.36',
    );
    expect(WebViewCompat.chromeLikeUserAgent('Mozilla/5.0 (iPhone)'), isNull);
    expect(WebViewCompat.chromeLikeUserAgent(null), isNull);
  });
}
