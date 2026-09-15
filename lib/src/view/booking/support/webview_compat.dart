import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;

/// To'lov WebView'ini brauzer (Safari / Chrome) xatti-harakatiga
/// yaqinlashtiruvchi yordamchilar. 3DS / ecom sahifalari brauzerda ishlab,
/// WebView'da "argument formati noto'g'ri" kabi xatolar bermasligi uchun.
class WebViewCompat {
  WebViewCompat._();

  /// Dart [Uri.parse] URL'ni qayta yozadimi (`|` → `%7C`, `%7e` → `~`,
  /// bo'shliq → `%20` ...). WebView `loadRequest` aynan qayta yozilgan
  /// satrni yuklaydi, brauzer esa xom satrni — imzoli so'rovlar buziladi.
  static bool changesWhenParsed(String url) {
    try {
      return Uri.parse(url).toString() != url;
    } catch (_) {
      return true;
    }
  }

  /// Xom URL'ni Dart [Uri] normalizatsiyasisiz yuklash uchun sahifa —
  /// `location.replace` tarixga ortiqcha yozuv qoldirmaydi.
  static String rawRedirectHtml(String rawUrl) => '<!doctype html><html><head>'
      '<meta name="viewport" content="width=device-width"></head><body>'
      '<script>location.replace(${_scriptSafeString(rawUrl)});</script>'
      '</body></html>';

  /// `<script>` ichiga xavfsiz JS satr literali: `</script>` va HTML
  /// belgilari teg ichidan chiqib ketmasligi uchun `\uXXXX` ga o'tkaziladi.
  static String _scriptSafeString(String value) => jsonEncode(value)
      .replaceAll('<', r'\u003c')
      .replaceAll('>', r'\u003e')
      .replaceAll('&', r'\u0026')
      .replaceAll('\u2028', r'\u2028')
      .replaceAll('\u2029', r'\u2029');

  /// iOS'da Safari bilan bir xil User-Agent. WKWebView standart UA'sida
  /// `Version/..` va `Safari/..` bo'lmaydi — ba'zi to'lov/3DS sahifalari uni
  /// qo'llab-quvvatlanmaydigan brauzer deb boshqacha ishlaydi.
  static String? iosSafariUserAgent() {
    if (!Platform.isIOS) return null;
    final match = RegExp(r'(\d+)\.(\d+)(?:\.(\d+))?')
        .firstMatch(Platform.operatingSystemVersion);
    if (match == null) return null;
    final major = match[1]!;
    final minor = match[2]!;
    final osVersion = [major, minor, if (match[3] != null) match[3]!].join('_');
    return 'Mozilla/5.0 (iPhone; CPU iPhone OS $osVersion like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) '
        'Version/$major.$minor Mobile/15E148 Safari/604.1';
  }

  /// Android WebView User-Agent'idan WebView belgilarini (`; wv`,
  /// `Version/4.0`) olib tashlaydi — Chrome bilan bir xil bo'ladi. Ba'zi
  /// to'lov/3DS sahifalari WebView'ni aniqlab, boshqacha ishlaydi.
  /// WebView UA bo'lmasa `null`.
  static String? chromeLikeUserAgent(String? webViewUserAgent) {
    final ua = webViewUserAgent?.trim() ?? '';
    if (!ua.contains('; wv)')) return null;
    return ua
        .replaceFirst('; wv)', ')')
        .replaceFirst(RegExp(r' Version/\d+(\.\d+)*'), '');
  }

  /// Yangi oyna (`window.open`, `target="_blank"`, mavjud bo'lmagan nomli
  /// oyna) so'rovlarini joriy oynaga yo'naltiradi.
  ///
  /// Sabab: WebView'da yangi oyna yo'q — iOS (`webview_flutter_wkwebview`) va
  /// Android plagini bunday so'rovni joriy WebView'da **qayta** yuklaydi va
  /// POST forma `body`si yo'qoladi; 3DS/ecom serveri argumentlarsiz so'rov
  /// oladi. Forma nishonini `_self` qilsak, brauzer uni to'liq (body bilan)
  /// o'zi yuboradi. Mavjud iframe nomiga yo'naltirilgan formalar tegilmaydi.
  static const String popupShimScript = r'''
(function () {
  if (window.__mysafarCompat) return;
  window.__mysafarCompat = true;
  function report(type, data) {
    try {
      if (window.MySafarDebug && window.MySafarDebug.postMessage) {
        window.MySafarDebug.postMessage(JSON.stringify({ type: type, data: data }));
      }
    } catch (e) {}
  }
  var SAME_WINDOW = { '': 1, '_self': 1, '_top': 1, '_parent': 1 };
  function frameExists(name) {
    try {
      var list = document.getElementsByName(name);
      for (var i = 0; i < list.length; i++) {
        var tag = list[i].tagName;
        if (tag === 'IFRAME' || tag === 'FRAME') return true;
      }
    } catch (e) {}
    return false;
  }
  function retarget(el, kind) {
    var target = (el.getAttribute && el.getAttribute('target')) || el.target || '';
    if (SAME_WINDOW[String(target).toLowerCase()] || frameExists(target)) return;
    report('compat-retarget', { kind: kind, from: target, to: '_self', action: el.action || el.href || '' });
    el.target = '_self';
  }
  document.addEventListener('submit', function (e) {
    if (e.target && e.target.tagName === 'FORM') retarget(e.target, 'form');
  }, true);
  var nativeSubmit = HTMLFormElement.prototype.submit;
  HTMLFormElement.prototype.submit = function () {
    retarget(this, 'form.submit()');
    return nativeSubmit.apply(this, arguments);
  };
  if (HTMLFormElement.prototype.requestSubmit) {
    var nativeRequestSubmit = HTMLFormElement.prototype.requestSubmit;
    HTMLFormElement.prototype.requestSubmit = function () {
      retarget(this, 'form.requestSubmit()');
      return nativeRequestSubmit.apply(this, arguments);
    };
  }
  document.addEventListener('click', function (e) {
    var link = e.target && e.target.closest ? e.target.closest('a[target]') : null;
    if (link) retarget(link, 'link');
  }, true);
  window.open = function (url, name) {
    var href = url == null ? '' : String(url);
    report('compat-window.open', { url: href, name: name || '' });
    if (href && href !== 'about:blank') window.location.assign(href);
    return window;
  };
})();
''';
}
