import 'package:get_storage/get_storage.dart';
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
    final err = error;
    final locale = GetStorage().read<String>('lang') ?? 'uz';

    if (err is Map) {
      final extracted = _extractErrorMessage(err, locale);
      if (extracted != null && extracted.isNotEmpty) return extracted;
    }

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
      ['message'],
      ['data', 'message'],
      ['error', 'data', 'message'],
      ['error', 'message'],
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
      ['data', 'message'],
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

  gatewayTimeout_504,

  // dio error
  dio_error,

  // emtpy response
  emptyResponse,

  /// unknown error
  other
}
