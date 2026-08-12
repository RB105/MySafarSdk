import 'dart:convert' show jsonDecode;

import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

abstract class NetworkResponse {
  const NetworkResponse();
}

// success response
final class NetworkSuccessResponse<T> extends NetworkResponse {
  // making flexible
  final T data;
  const NetworkSuccessResponse({required this.data});
}

// error response
final class NetworkErrorResponse<T> extends NetworkResponse {
  final T error;
  final ErrorType? errorType;
  const NetworkErrorResponse({required this.error, this.errorType});

  String getError() {
    // Server va tarmoq darajasidagi xatoliklar (server o'chgan, ulanish yo'q,
    // 5xx, yaroqsiz shlyuz) uchun backend qaytargan "xom" javob texnik va
    // foydalanuvchiga tushunarsiz bo'ladi (HTML, stack trace, nginx xabari).
    // Shu sabab bunday holatlarda body'dan xabar chiqarmasdan, tayyor va
    // tushunarli tarjima matnini ko'rsatamiz.
    if (_isServerOrNetworkError) {
      return _localizedMessage();
    }

    // Client xatolari (400/401/403/404/409): backend odatda ma'noli biznes
    // xabarini yuboradi — avval o'shani, topilmasa tarjima matnini ko'rsatamiz.
    final err = error;
    // Server xabarlari faqat uz/ru/en da keladi — qo'shimcha tillar
    // (kk, tg → ru; tr → en) shu uchtasiga moslanadi.
    final locale = dataLang();

    if (err is Map) {
      final extracted = _extractErrorMessage(err, locale);
      if (extracted != null && extracted.isNotEmpty) return extracted;
    }

    // Xabar matn ko'rinishida ham kelishi mumkin: servis qatlami body'dan
    // chiqarib olgan xabar, JSON matni yoki `{uz: ..., ru: ..., en: ...}`
    // ko'rinishidagi Map'ning matnga aylantirilgani. Bularning hammasidan
    // foydalanuvchi tilidagi xabarni ajratib olamiz — aks holda server
    // aytgan aniq sabab o'rniga umumiy "static" matn chiqib qoladi.
    if (err is String) {
      final extracted = _messageFromText(err, locale);
      if (extracted != null && extracted.isNotEmpty) return extracted;
    }

    return _localizedMessage();
  }

  /// Matn ko'rinishidagi xatodan foydalanuvchiga ko'rsatiladigan xabarni
  /// ajratadi. Ichki/texnik matnlar (HTTP status matni, "No connection" kabi
  /// zaxira qiymatlar, HTML) uchun `null` qaytaradi — bunday holatda tayyor
  /// tarjima matni ko'rsatiladi.
  String? _messageFromText(String raw, String locale) {
    final text = raw.trim();
    if (text.isEmpty || _isTechnicalMessage(text)) return null;
    // HTML/stack trace — foydalanuvchiga ko'rsatilmaydi.
    if (text.startsWith('<')) return null;

    if (text.startsWith('{') || text.startsWith('[')) {
      // 1. To'g'ri JSON matni bo'lsa — Map bo'yicha odatiy qidiruv.
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          final extracted = _extractErrorMessage(decoded, locale);
          if (extracted != null && extracted.isNotEmpty) return extracted;
        }
      } catch (_) {
        // JSON emas — quyida Dart Map matni sifatida tekshiriladi.
      }
      // 2. `{uz: ..., ru: ..., en: ...}` — Map.toString() ko'rinishi
      //    (kalitlar tirnoqsiz, shu sababli JSON sifatida o'qilmaydi).
      final inline = _parseInlineLocaleMap(text);
      if (inline != null) {
        final picked = _pickLocale(inline, locale);
        if (picked != null) return picked;
      }
      return null;
    }

    return text;
  }

  /// `{uz: ..., ru: ..., en: ...}` matnini til→xabar Map'iga o'giradi.
  /// Qiymat ichidagi vergul xabarni bo'lib yubormaydi — ajratish faqat
  /// keyingi til kaliti uchraganda bo'ladi.
  Map<String, String>? _parseInlineLocaleMap(String text) {
    if (!text.startsWith('{') || !text.endsWith('}')) return null;
    final inner = text.substring(1, text.length - 1);
    final matches = _inlineLocaleKey.allMatches(inner).toList();
    if (matches.isEmpty) return null;
    final map = <String, String>{};
    for (int i = 0; i < matches.length; i++) {
      final key = matches[i].group(1)!;
      final int start = matches[i].end;
      final int end = i + 1 < matches.length ? matches[i + 1].start : inner.length;
      final value = inner.substring(start, end).trim();
      if (value.isNotEmpty) map[key] = value;
    }
    return map.isEmpty ? null : map;
  }

  static final RegExp _inlineLocaleKey =
      RegExp(r'(?:^|,)\s*(uz|ru|en)\s*:\s*');

  /// Ichki (foydalanuvchiga ma'nosiz) matnlar: HTTP status matni va kod
  /// ichidagi zaxira qiymatlar. Bularning o'rniga tarjima matni chiqadi.
  static const Set<String> _technicalMessages = {
    'cancelled',
    'null',
    'empty',
    'error',
    'unknown error',
    'something went wrong',
    'bad response',
    'no connection',
    'connect timeout',
    'receive timeout',
    'send timeout',
    'failed to parse tariffs',
    'unexpected airports response',
    'unexpected centrum response',
    // HTTP status matnlari (`response.statusMessage`).
    'bad request',
    'unauthorized',
    'payment required',
    'forbidden',
    'not found',
    'method not allowed',
    'conflict',
    'payload too large',
    'request entity too large',
    'unprocessable entity',
    'too many requests',
    'internal server error',
    'not implemented',
    'bad gateway',
    'service unavailable',
    'gateway timeout',
  };

  /// Dart istisnolari matnga aylanib kelganda ham foydalanuvchiga
  /// ko'rsatilmasligi kerak ("Exception: ...", "type 'Null' is not a
  /// subtype ...", stack trace va h.k.).
  static const List<String> _exceptionMarkers = [
    'exception',
    'stack trace',
    'is not a subtype',
    'null check operator',
    'nosuchmethod',
    '#0 ',
  ];

  bool _isTechnicalMessage(String text) {
    final lower = text.toLowerCase();
    if (_technicalMessages.contains(lower)) return true;
    // Juda uzun matn — deyarli har doim texnik chiqindi (HTML, trace).
    if (text.length > 400) return true;
    for (final marker in _exceptionMarkers) {
      if (lower.contains(marker)) return true;
    }
    return false;
  }

  /// Server o'chishi, ulanish yo'qligi yoki 5xx kabi infratuzilma xatolarimi?
  /// Bularda backend body foydasiz bo'lgani uchun to'g'ridan-to'g'ri tayyor
  /// tarjima matni ko'rsatiladi.
  bool get _isServerOrNetworkError {
    switch (errorType) {
      case ErrorType.connectTimeout:
      case ErrorType.receiveTimeout:
      case ErrorType.sendTimeout:
      case ErrorType.connectionError:
      case ErrorType.internalServer_500:
      case ErrorType.badGateway_502:
      case ErrorType.serviceUnavailable_503:
      case ErrorType.gatewayTimeout_504:
      case ErrorType.dio_error:
        return true;
      default:
        return false;
    }
  }

  /// `errorType` bo'yicha foydalanuvchiga tushunarli tarjima matnini qaytaradi.
  String _localizedMessage() {
    switch (errorType) {
      //
      case ErrorType.connectTimeout:
      case ErrorType.receiveTimeout:
      case ErrorType.sendTimeout:
        return "error_time_out".tr();

      case ErrorType.connectionError:
        return "error_dio".tr();

      //
      case ErrorType.badResponse_400:
        return "error_400".tr();
      case ErrorType.unAuthorized_401:
        return "error_401".tr();
      case ErrorType.forbidden_403:
        return "error_403".tr();
      case ErrorType.conflict_409:
        return "error_409".tr();
      case ErrorType.notFound_404:
        return "error_404".tr();

      //
      case ErrorType.internalServer_500:
        return "error_500".tr();
      case ErrorType.badGateway_502:
        return "error_502".tr();
      case ErrorType.serviceUnavailable_503:
        return "error_503".tr();
      case ErrorType.gatewayTimeout_504:
        return "error_504".tr();

      //
      case ErrorType.dio_error:
        return "error_dio".tr();

      //
      default:
        return "error_other".tr();
    }
  }

  /// Web (extractErrorMessage) bilan bir xil: backend xato xabarini turli
  /// mumkin bo'lgan joylardan qidiradi. `err` bu odatda `response.data` (body).
  ///
  /// Til-spetsifik (`{uz, ru, en}`) yo'llar avval tekshiriladi — shunda
  /// bir xil nomli umumiy yo'l (masalan `message` obyekt bo'lsa) til xabarini
  /// "yamlab" yubormaydi.
  String? _extractErrorMessage(Map err, String locale) {
    // 1. Til bo'yicha lokalizatsiyalangan xabarlar ({uz, ru, en} Map'i).
    const localizedRoots = <List<String>>[
      // Yangi backend formati: {"code": "...", "detail": {uz, ru, en}}
      // (masalan bilet vozvrati endpointlari).
      ['detail'],
      ['data', 'detail'],
      ['error', 'detail'],
      ['message'],
      ['messages'],
      ['data', 'message'],
      ['data', 'messages'],
      ['error', 'data', 'message'],
      ['error', 'message'],
      ['error', 'messages'],
      ['data', 'humo', 'error', 'message'],
      ['humo', 'error', 'message'],
      ['data', 'uzcard', 'error', 'message'],
      ['uzcard', 'error', 'message'],
      ['errors', 'message'],
      ['data'],
      ['error', 'data'],
      ['error'],
      <String>[], // root'ning o'zi {uz, ru, en} bo'lishi mumkin
    ];
    for (final path in localizedRoots) {
      final node = _dig(err, path);
      if (node is Map) {
        final picked = _pickLocale(node, locale);
        if (picked != null) return picked;
      }
    }

    // 2. Oddiy matnli xabarlar (String yoki String'lar ro'yxati).
    const stringPaths = <List<String>>[
      ['message'],
      ['messages'],
      ['data', 'message'],
      ['data', 'messages'],
      ['error', 'data', 'message'],
      ['detail'],
      ['data', 'detail'],
      ['error', 'data', 'detail'],
      ['data', 'data', 'message'],
      ['error', 'data', 'data', 'message'],
      ['data', 'data', 'detail'],
      ['error', 'data', 'data', 'detail'],
      ['res', 'data', 'message'],
      ['error', 'res', 'data', 'message'],
      ['data', 'humo', 'error', 'message'],
      ['humo', 'error', 'message'],
      ['data', 'uzcard', 'error', 'message'],
      ['uzcard', 'error', 'message'],
      ['message', 'description'],
      ['error', 'message', 'description'],
      ['error', 'message'],
      ['errors'],
      ['data', 'error'],
      ['error', 'data', 'error'],
      ['error'],
      ['error', 'detail'],
      ['error', 'message', 'detail'],
      ['card_number'],
      ['data', 'card_number'],
    ];
    for (final path in stringPaths) {
      final value = _digString(err, path);
      if (value != null) return value;
    }

    // 3. Maydon-validatsiya xatolari: {field: ["msg1", "msg2"]} —
    //    yuqoridagi qat'iy yo'llar qamramaydi, shu sbabli to'g'ridan-to'g'ri olamiz.
    final fieldMessages = <String>[];
    err.forEach((key, value) {
      if (value is List) {
        for (final msg in value) {
          if (msg is String && msg.trim().isNotEmpty) {
            fieldMessages.add('$key: ${msg.trim()}');
          }
        }
      }
    });
    if (fieldMessages.isNotEmpty) return fieldMessages.join('\n');

    return null;
  }

  /// `path` bo'yicha ichma-ich kalitlarga kirib, oxirgi qiymatni qaytaradi
  /// (Map bo'lmasa yoki kalit yo'q bo'lsa — `null`).
  dynamic _dig(dynamic root, List<String> path) {
    dynamic current = root;
    for (final key in path) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  /// `path` bo'yicha yurib, oxirida String yoki String'lar ro'yxatining
  /// birinchi bo'sh bo'lmagan elementini qaytaradi.
  String? _digString(dynamic root, List<String> path) {
    final current = _dig(root, path);
    if (current is String) {
      final trimmed = current.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (current is List) {
      for (final e in current) {
        if (e is String && e.trim().isNotEmpty) return e.trim();
      }
    }
    return null;
  }

  /// `{uz, ru, en}` ko'rinishidagi Map'dan joriy til xabarini tanlaydi,
  /// til topilmasa boshqa tillarga (uz → ru → en) fallback qiladi.
  String? _pickLocale(Map map, String locale) {
    final value = map[locale] ?? map['uz'] ?? map['ru'] ?? map['en'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }
}

enum ErrorType {
  // timeout errors
  connectTimeout,

  receiveTimeout,

  sendTimeout,

  connectionError,

  // clint errors
  badResponse_400,

  unAuthorized_401,

  forbidden_403,

  conflict_409,

  notFound_404,

  // server errors
  internalServer_500,

  badGateway_502,

  serviceUnavailable_503,

  gatewayTimeout_504,

  // dio error
  dio_error,

  // emtpy response
  emptyResponse,

  /// unknown error
  other
}
