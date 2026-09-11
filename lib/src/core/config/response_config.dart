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

  /// Server qaytargan HTTP status kodi (bo'lsa). Analitikaga (`booking_failed`,
  /// `payment_failed`) xatoning sababi bilan birga yuboriladi — aks holda
  /// hisobotda faqat "Nomalum xatolik" ko'rinadi va sabab yo'qoladi.
  final int? statusCode;

  const NetworkErrorResponse({
    required this.error,
    this.errorType,
    this.statusCode,
  });

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
      final usable = _usableMessage(_extractErrorMessage(err, locale));
      if (usable != null) return usable;
    }

    // Xabar matn ko'rinishida ham kelishi mumkin: servis qatlami body'dan
    // chiqarib olgan xabar, JSON matni yoki `{uz: ..., ru: ..., en: ...}`
    // ko'rinishidagi Map'ning matnga aylantirilgani. Bularning hammasidan
    // foydalanuvchi tilidagi xabarni ajratib olamiz — aks holda server
    // aytgan aniq sabab o'rniga umumiy "static" matn chiqib qoladi.
    if (err is String) {
      final usable = _usableMessage(_messageFromText(err, locale));
      if (usable != null) return usable;
    }

    return _localizedMessage();
  }

  /// Ajratib olingan xabarni foydalanuvchiga ko'rsatsa bo'ladimi?
  ///
  /// Uch bosqich:
  ///  1. Tanish server/provayder xabari bo'lsa — ilova tilidagi tarjimasi;
  ///  2. Texnik/ichki xabar bo'lsa (`Given token not valid…` kabi) — `null`,
  ///     ya'ni tayyor tarjima matni (`error_401`) ishlatiladi;
  ///  3. Aks holda serverning o'z xabari o'zgarishsiz ko'rsatiladi.
  String? _usableMessage(String? extracted) {
    final text = extracted?.trim() ?? '';
    if (text.isEmpty) return null;

    final translated = _translateServerMessage(text);
    if (translated != null) return translated;

    if (_isTechnicalMessage(text)) return null;
    return text;
  }

  /// Backend/provayder faqat ingliz tilida qaytaradigan xabarlarni ilova
  /// tiliga o'giradi.
  ///
  /// Ro'yxat AppMetrica'dagi haqiqiy `api_error` / `booking_failed` /
  /// `payment_failed` xabarlaridan yig'ilgan — foydalanuvchi ilgari
  /// "Mandatory booking details missing-Passport Number" kabi matnlarni
  /// ko'rar edi. Kalitlar KICHIK harfda va xabar BOSHLANISHI bo'yicha
  /// solishtiriladi (server oxiriga tafsilot qo'shishi mumkin).
  static const Map<String, String> _serverMessageKeys = {
    'mandatory booking details missing-passport number':
        'srv_passport_number_required',
    'a passenger accompanying a child or infant':
        'srv_adult_required_for_child',
    'invalid passenger nationality': 'srv_invalid_nationality',
    'invalid passport expiry date': 'srv_invalid_passport_expiry',
    'invalid passport number': 'srv_invalid_passport_number',
    'the surname is incorrect': 'srv_invalid_surname',
    'the document type is incorrect': 'srv_invalid_document_type',
    'invalid telephone number': 'srv_invalid_phone',
    'client_email: enter a valid email address': 'srv_invalid_email',
    'enter a valid email address': 'srv_invalid_email',
    'no availability on requested date': 'srv_no_availability',
    'no itinerary found': 'srv_itinerary_not_found',
    'fail to receive a response from the supplier': 'srv_supplier_no_response',
    'invalid ticket status: paid': 'srv_ticket_already_paid',
    'invalid ticket status: awaitpayment': 'srv_ticket_awaiting_payment',
    'ticket already ticketed': 'srv_ticket_already_ticketed',
    'transaction not found': 'srv_transaction_not_found',
    'user does not exist': 'srv_user_not_found',
    'user with this document number already exists':
        'srv_document_already_exists',
    'unknown error. you should copy pid': 'srv_contact_support_pid',
  };

  String? _translateServerMessage(String text) {
    final normalized = text.toLowerCase().trim();
    for (final entry in _serverMessageKeys.entries) {
      if (normalized.startsWith(entry.key)) return entry.value.tr();
    }
    return null;
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

      final inline = _parseInlineLocaleMap(text);
      if (inline != null) {
        final picked = _pickLocale(inline, locale);
        if (picked != null) return picked;
      }
      return null;
    }

    return text;
  }


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
    'failed to parse flight info',
    'unexpected airports response',
    'unexpected centrum response',
    'unexpected destination list response',
    'unexpected destination detail response',
    'empty city',
    'destination not found',
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


  static const List<String> _exceptionMarkers = [
    'exception',
    'stack trace',
    'is not a subtype',
    'null check operator',
    'nosuchmethod',
    '#0 ',
    // Auth/token bilan bog'liq ichki xabarlar — backend ularni `detail`
    // maydonida ingliz tilida qaytaradi va ilgari to'g'ridan-to'g'ri
    // foydalanuvchiga ko'rsatilardi ("Given token not valid for any token
    // type"). Bunday holatda `error_401` matni ancha tushunarli.
    'given token not valid',
    'token_not_valid',
    'token is expired',
    'authorization header must contain',
    'bad_authorization_header',
    'no active account',
    'credentials were not provided',
    // Backend Django/DRF (Python) — kutilmagan holatlarda tayyor
    // "tushunarli" xabar o'rniga xom traceback/exception matni kelib
    // qolishi mumkin. Bunday matn foydalanuvchiga umuman ma'nosiz —
    // shu markerlar ko'rinsa ham tarjima matni ko'rsatiladi.
    'traceback (most recent call last)',
    'typeerror:',
    'valueerror:',
    'keyerror:',
    'attributeerror:',
    'indexerror:',
    'file "',
    'django.core.exceptions',
    'django.db',
    'rest_framework.exceptions',
    'doesnotexist',
    'multivaluedictkeyerror',
    'integrityerror',
    'object at 0x',
  ];

  bool _isTechnicalMessage(String text) {
    final lower = text.toLowerCase();
    if (_technicalMessages.contains(lower)) return true;

    if (text.length > 400) return true;
    for (final marker in _exceptionMarkers) {
      if (lower.contains(marker)) return true;
    }

    // Bo'shliqsiz, pastki chiziqli yagona so'z (masalan
    // "duplicate_booking_request") — bu odam yozgan gap emas, ichki kod
    // nomi. Bunday "so'z" ma'nosiz ko'rinadi, tayyor tarjima matni
    // ko'rsatiladi. Haqiqiy server xabarlari doim bo'shliqli gap bo'ladi.
    if (!lower.contains(' ') && lower.contains('_') && lower.length > 3) {
      return true;
    }
    return false;
  }

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
      case ErrorType.serverError_5xx:
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

      // BARCHA 5xx — foydalanuvchi uchun bitta tushunarli matn: muammo
      // serverda va o'zi hal bo'ladi, qayta urinish kerak. 500/502/503/504
      // orasidagi farq oddiy foydalanuvchiga hech narsa bermaydi (Cloudflare
      // "The origin web server returned an invalid or incomplete response"
      // kabi matnlar esa umuman tushunarsiz). Aniq sabab `trackApiError`
      // orqali analitikaga yoziladi — u ekranda emas, hisobotda kerak.
      case ErrorType.internalServer_500:
      case ErrorType.badGateway_502:
      case ErrorType.serviceUnavailable_503:
      case ErrorType.gatewayTimeout_504:
      case ErrorType.serverError_5xx:
        return "error_server_retry".tr();

      //
      case ErrorType.dio_error:
        return "error_dio".tr();

      // Server 200/207 qaytardi-yu, natija bo'sh — bu texnik xato emas,
      // shuning uchun "Nomalum xatolik" o'rniga aniq xabar ko'rsatiladi.
      case ErrorType.emptyResponse:
        return "tickets_not_found".tr();

      // Backend `tr_id`siz javob qaytardi — buyurtma serverda yaratilgan
      // bo'lishi mumkin, foydalanuvchini "Noma'lum xatolik" bilan
      // qo'rqitmasdan, "Buyurtmalarim"ni tekshirishga yo'naltiramiz.
      case ErrorType.bookingMissingTrId:
        return "booking_missing_tr_id_notice".tr();

      // Aniqlanmagan (kutilmagan) xato — "hozircha chiqmadi" kabi tushunarsiz
      // umumiy matn o'rniga, bor bo'lgan HTTP status kodi ko'rsatiladi
      // (topilmasa — umumiy matn) — foydalanuvchi va support uchun aniqroq.
      default:
        return statusCode == null
            ? "error_other".tr()
            : "error_other_code".tr(namedArgs: {"code": "$statusCode"});
    }
  }

  String? _extractErrorMessage(Map err, String locale) {
    const localizedRoots = <List<String>>[

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
      <String>[],
    ];
    for (final path in localizedRoots) {
      final node = _dig(err, path);
      if (node is Map) {
        final picked = _pickLocale(node, locale);
        if (picked != null) return picked;
      }
    }


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

  /// Yuqoridagilardan boshqa har qanday 5xx (505, 507, Cloudflare 520–527...).
  /// Ilgari bunday kodlar `dio_error` ga tushib, foydalanuvchi "Internetga
  /// ulanishda muammo" xabarini ko'rar edi — aslida muammo serverda.
  serverError_5xx,

  // dio error
  dio_error,

  // emtpy response
  emptyResponse,

  /// Backend nuqsoni: `booking-create` `success: true` bilan javob berdi,
  /// lekin ilova kutgan `tr_id` o'rniga xom `data.book.order` konvertida
  /// qaytardi — buyurtma serverda yaratilgan bo'lishi mumkin, lekin ilova
  /// to'lovni OTP orqali tasdiqlash uchun davom eta olmaydi.
  bookingMissingTrId,

  /// unknown error
  other
}
