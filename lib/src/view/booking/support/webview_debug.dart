import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// To'lov WebView'i uchun **faqat debug** diagnostikasi: navigatsiyalar,
/// URL normalizatsiyasi, sahifa holati, JS xatolari, form / fetch / XHR
/// so'rovlari va javoblari konsolga `[MySafar WebView]` bilan yoziladi.
///
/// Karta raqami, CVV, muddat, OTP kabi maydonlar maskalanadi; release
/// build'da hech narsa yozilmaydi va skript kiritilmaydi.
class WebViewDebug {
  WebViewDebug._();

  static bool get enabled => kDebugMode;

  /// JavaScript kanal nomi — sahifadagi hook'lar shu orqali xabar yuboradi.
  static const String channelName = 'MySafarDebug';

  static void log(String message) {
    if (!enabled) return;
    final text = maskPan(message);
    // Logcat bitta qatorni ~4000 baytda kesadi — bo'lib chiqaramiz.
    const chunk = 900;
    for (int i = 0; i < text.length; i += chunk) {
      final end = (i + chunk < text.length) ? i + chunk : text.length;
      debugPrint(
        '[MySafar WebView]${i == 0 ? '' : ' …'} ${text.substring(i, end)}',
        wrapWidth: 1200,
      );
    }
  }

  /// 12–19 raqamli ketma-ketliklarni (karta raqami) `8600****9012` ga almashtiradi.
  static String maskPan(String text) => text.replaceAllMapped(
        RegExp(r'(?<!\d)(\d{4})\d{4,11}(\d{4})(?!\d)'),
        (m) => '${m[1]}****${m[2]}',
      );

  /// Dart [Uri.parse] URL'ni qanday qayta yozishini ko'rsatadi. WebView
  /// (iOS ham, Android ham) aynan `Uri.parse(url).toString()` ni yuklaydi,
  /// brauzer esa xom satrni oladi — farq bo'lsa shu yerda ko'rinadi.
  static void logUrlNormalization(String raw) {
    if (!enabled) return;
    log('url raw:    $raw');
    final Uri parsed;
    try {
      parsed = Uri.parse(raw);
    } catch (e) {
      log('url PARSE XATOSI: $e');
      return;
    }
    final normalized = parsed.toString();
    if (normalized == raw) {
      log('url Dart Uri: o\'zgarmadi');
      return;
    }
    log('url Dart Uri: O\'ZGARDI -> $normalized');
    final rawQuery = raw.contains('?') ? raw.split('?').skip(1).join('?') : '';
    final normQuery = parsed.query;
    final rawParts = rawQuery.split('#').first.split('&');
    final normParts = normQuery.split('&');
    for (int i = 0; i < rawParts.length || i < normParts.length; i++) {
      final a = i < rawParts.length ? rawParts[i] : '(yo\'q)';
      final b = i < normParts.length ? normParts[i] : '(yo\'q)';
      if (a != b) log('  param[$i] raw="$a"  dart="$b"');
    }
    if (raw.split('?').first != normalized.split('?').first) {
      log('  path raw="${raw.split('?').first}" '
          'dart="${normalized.split('?').first}"');
    }
  }

  /// Sahifaga kiritiladigan hook'lar (har `onPageFinished` da; takroriy
  /// kiritishdan himoyalangan). Hook'lar karta maydonlarini maskalaydi.
  static const String injectedScript = r'''
(function () {
  function send(type, data) {
    try {
      var payload = JSON.stringify({ type: type, data: data });
      if (window.MySafarDebug && window.MySafarDebug.postMessage) {
        window.MySafarDebug.postMessage(payload);
      }
    } catch (e) {}
  }
  var SENSITIVE = /pan|card|cvv|cvc|cvn|cv2|exp|month|year|mm|yy|number|pin|otp|sms|code|pass|secret/i;
  function maskValue(name, value) {
    value = value == null ? '' : String(value);
    if (SENSITIVE.test(name || '')) return '***(' + value.length + ')';
    value = value.replace(/\d{12,19}/g, function (d) {
      return d.slice(0, 4) + '****' + d.slice(-4);
    });
    return value.length > 120 ? value.slice(0, 120) + '…(' + value.length + ')' : value;
  }
  function describeForm(form) {
    var fields = [];
    try {
      for (var i = 0; i < form.elements.length; i++) {
        var el = form.elements[i];
        if (!el.name) continue;
        fields.push(el.name + '[' + (el.type || el.tagName) + ']=' + maskValue(el.name, el.value));
      }
    } catch (e) {}
    return {
      action: form.action, method: (form.method || 'get').toUpperCase(),
      target: form.target || '', enctype: form.enctype || '', fields: fields
    };
  }
  function snapshot(reason) {
    var forms = [], frames = [];
    try { for (var i = 0; i < document.forms.length; i++) forms.push(describeForm(document.forms[i])); } catch (e) {}
    try {
      var ifr = document.getElementsByTagName('iframe');
      for (var j = 0; j < ifr.length; j++) frames.push({ src: ifr[j].src, name: ifr[j].name });
    } catch (e) {}
    var text = '';
    try { text = (document.body && document.body.innerText || '').replace(/\s+/g, ' ').trim(); } catch (e) {}
    send('snapshot', {
      reason: reason, href: location.href, title: document.title, referrer: document.referrer,
      readyState: document.readyState, userAgent: navigator.userAgent,
      cookieEnabled: navigator.cookieEnabled, cookieCount: (document.cookie ? document.cookie.split(';').length : 0),
      forms: forms, iframes: frames, text: maskValue('', text.slice(0, 1500))
    });
  }
  window.__mysafarDebugSnapshot = snapshot;
  if (window.__mysafarDebugInstalled) { snapshot('page-finished'); return; }
  window.__mysafarDebugInstalled = true;

  window.addEventListener('error', function (e) {
    send('js-error', { message: e.message, source: e.filename, line: e.lineno, col: e.colno });
  });
  window.addEventListener('unhandledrejection', function (e) {
    send('js-rejection', { reason: String(e.reason && (e.reason.stack || e.reason.message) || e.reason) });
  });
  document.addEventListener('submit', function (e) {
    send('form-submit', describeForm(e.target));
  }, true);
  var nativeSubmit = HTMLFormElement.prototype.submit;
  HTMLFormElement.prototype.submit = function () {
    send('form-submit()', describeForm(this));
    return nativeSubmit.apply(this, arguments);
  };
  var nativeOpen = window.open;
  window.open = function (url, target, features) {
    send('window.open', { url: String(url), target: target || '' });
    return nativeOpen ? nativeOpen.apply(window, arguments) : null;
  };
  if (window.fetch) {
    var nativeFetch = window.fetch;
    window.fetch = function (input, init) {
      var url = typeof input === 'string' ? input : (input && input.url);
      var method = (init && init.method) || (input && input.method) || 'GET';
      send('fetch', { method: method, url: url });
      return nativeFetch.apply(this, arguments).then(function (res) {
        try {
          res.clone().text().then(function (body) {
            send('fetch-response', { url: url, status: res.status, body: maskValue('', body.slice(0, 800)) });
          });
        } catch (e) {}
        return res;
      }, function (err) {
        send('fetch-failed', { url: url, error: String(err) });
        throw err;
      });
    };
  }
  var xhrOpen = XMLHttpRequest.prototype.open;
  var xhrSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open = function (method, url) {
    this.__mysafar = { method: method, url: String(url) };
    return xhrOpen.apply(this, arguments);
  };
  XMLHttpRequest.prototype.send = function (body) {
    var info = this.__mysafar || {};
    var xhr = this;
    send('xhr', { method: info.method, url: info.url, body: maskValue('', body == null ? '' : String(body).slice(0, 400)) });
    xhr.addEventListener('loadend', function () {
      var text = '';
      try { text = typeof xhr.responseText === 'string' ? xhr.responseText : ''; } catch (e) {}
      send('xhr-response', { url: info.url, status: xhr.status, body: maskValue('', text.slice(0, 800)) });
    });
    return xhrSend.apply(this, arguments);
  };
  snapshot('page-finished');
})();
''';
}
