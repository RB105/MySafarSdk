import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';

import 'refund_models.dart';

/// Bilet vozvrati — foydalanuvchi ARIZA qoldiradi, refundni support bajaradi.
///
/// Mobil faqat ikki endpoint bilan ishlaydi:
///   • `POST /tickets/refund/request`  — ariza yuborish;
///   • `GET  /tickets/refund/requests` — arizalar holati.
/// `/tickets/refund` (to'g'ridan-to'g'ri refund) ichki xodimlar uchun va bu
/// yerda ATAYLAB chaqirilmaydi (server `403 USE_REFUND_REQUEST` beradi).
class RefundService with RequestConfig {
  /// Foydalanuvchining barcha arizalari (eng yangisi birinchi).
  ///
  /// Muvaffaqiyatda `NetworkSuccessResponse<List<RefundRequestModel>>`,
  /// xatoda `NetworkErrorResponse<RefundFailure>` qaytadi.
  Future<NetworkResponse> getRequests() async {
    if (!hasAccessToken) {
      return const NetworkErrorResponse<RefundFailure>(
        error: RefundFailure(code: 'UNAUTHORIZED', message: ''),
        errorType: ErrorType.unAuthorized_401,
      );
    }

    final response =
        await getRequest(endPoint: EndPoints.refund_requests, headers: true);

    if (response is NetworkSuccessResponse) {
      final list = parseRequests(response.data)
        // Server tartibiga tayanmaymiz — yangi ariza doim tepada tursin.
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      return NetworkSuccessResponse<List<RefundRequestModel>>(data: list);
    }
    return _asFailure(response);
  }

  /// Yangi ariza yuboradi. `201` da yaratilgan ariza qaytadi.
  ///
  /// [cardNumber] ni probel bilan yuborish mumkin — backend o'zi tozalaydi,
  /// lekin biz ham tozalab yuboramiz (ortiqcha `CARD_INVALID` bo'lmasin).
  /// [phoneNumber] bo'sh bo'lsa server profildagi raqamni oladi.
  Future<NetworkResponse> createRequest({
    required String billingId,
    required String cardNumber,
    String? cardHolder,
    String? phoneNumber,
    String? reason,
    RefundType refundType = RefundType.voluntary,
  }) async {
    if (!hasAccessToken) {
      return const NetworkErrorResponse<RefundFailure>(
        error: RefundFailure(code: 'UNAUTHORIZED', message: ''),
        errorType: ErrorType.unAuthorized_401,
      );
    }

    final response = await postRequest(
      endPoint: EndPoints.refund_request,
      headers: true,
      params: {
        'billing_id': billingId,
        'card_number': cardNumber.replaceAll(RegExp(r'\D'), ''),
        if (cardHolder != null && cardHolder.trim().isNotEmpty)
          'card_holder': cardHolder.trim(),
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phone_number': phoneNumber.trim(),
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        'refund_type': refundType.apiValue,
      },
    );

    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse<RefundRequestModel>(
        data: parseSingle(response.data) ?? const RefundRequestModel(),
      );
    }
    return _asFailure(response);
  }

  /// Xato javobini [RefundFailure] ga o'giradi: `code` UI mantiqi uchun,
  /// `message` esa allaqachon foydalanuvchi tilida (`detail.{uz,ru,en}` ni
  /// [NetworkErrorResponse.getError] o'zi ajratib beradi).
  NetworkResponse _asFailure(NetworkResponse response) {
    if (response is! NetworkErrorResponse) return response;
    final body = response.error;
    final code = (body is Map ? body['code'] : null)?.toString() ?? '';
    final message = response.getError();
    debugPrint('Refund error: code=$code message=$message');
    return NetworkErrorResponse<RefundFailure>(
      error: RefundFailure(code: code, message: message),
      errorType: response.errorType,
    );
  }

  // ── Javobni o'qish ─────────────────────────────────────────────────────
  //
  // Server javobi bir necha ko'rinishda kelishi mumkin, shu sababli o'qish
  // qat'iy bitta shaklga bog'lanmagan:
  //   {"results": [ {"success": true, "request": { … }} ]}   ← hozirgi
  //   {"success": true, "request": [ { … } ]}
  //   {"success": true, "request": { … }}
  //   {"results" | "requests" | "data": [ { … } ]}
  //   [ { … } ]
  // Har bir element o'ramda bo'lsa ichidagi ariza ajratib olinadi.

  /// Javobdagi barcha arizalar. Topilmasa bo'sh ro'yxat — bu xato emas
  /// (foydalanuvchida ariza yo'q holati).
  static List<RefundRequestModel> parseRequests(dynamic body) {
    // Avval ro'yxat qidiriladi; topilmasa body'ning o'zi bitta ariza
    // (yoki bitta o'ram) bo'lishi mumkin. Tartib muhim — aks holda bitta
    // ariza ikki marta qo'shilib ketardi.
    final list = _extractList(body);
    if (list.isNotEmpty) {
      return list
          .map(_unwrapRequest)
          .whereType<Map<String, dynamic>>()
          .map(RefundRequestModel.fromJson)
          .toList();
    }
    final single = _unwrapRequest(body);
    return single == null
        ? <RefundRequestModel>[]
        : [RefundRequestModel.fromJson(single)];
  }

  /// Javobdagi birinchi ariza (`POST` javobida bitta ariza qaytadi).
  static RefundRequestModel? parseSingle(dynamic body) {
    final list = parseRequests(body);
    return list.isEmpty ? null : list.first;
  }

  /// Ro'yxatga o'xshash qiymatni ajratadi (o'ram kalitlari bo'yicha).
  static List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is! Map) return const [];
    for (final key in const ['results', 'request', 'requests', 'data']) {
      final value = data[key];
      if (value is List) return value;
      if (value is Map) {
        if (_looksLikeRequest(value)) return [value];
        final nested = _extractList(value);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  /// Element to'g'ridan-to'g'ri ariza bo'lsa — o'zi, `{"success": true,
  /// "request": { … }}` kabi o'ramda bo'lsa — ichidagi ariza qaytadi.
  static Map<String, dynamic>? _unwrapRequest(dynamic item) {
    if (item is! Map) return null;
    if (_looksLikeRequest(item)) return Map<String, dynamic>.from(item);
    for (final key in const ['request', 'result', 'data']) {
      final value = item[key];
      if (value is Map && _looksLikeRequest(value)) {
        return Map<String, dynamic>.from(value);
      }
      if (value is List) {
        for (final e in value) {
          if (e is Map && _looksLikeRequest(e)) {
            return Map<String, dynamic>.from(e);
          }
        }
      }
    }
    return null;
  }

  /// Map ariza obyektiga o'xshaydimi (o'ram emasmi).
  static bool _looksLikeRequest(Map map) =>
      map.containsKey('billing_id') ||
      map.containsKey('refund_type') ||
      (map.containsKey('id') && map.containsKey('status'));
}
