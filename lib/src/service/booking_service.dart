import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show
        ErrorType,
        NetworkErrorResponse,
        NetworkResponse,
        NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/constants/end_points.dart' show EndPoints;
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'package:mysafar_sdk/src/core/enum/currency.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart' show dataLang;
import 'package:mysafar_sdk/src/core/tools/phone_format.dart';
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/model/remote/booking/payment_type_model.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/api_service.dart';
import 'package:provider/provider.dart' show Provider;

/// Eslatma (№37): bu yerdagi barcha so'rovlar `partnerToken: true` bilan
/// ketadi — `Authorization: Token <partner>` yuboriladi, foydalanuvchi
/// access token'i umuman ishlatilmaydi. Shu sabab avval har so'rovdan oldin
/// chaqirilgan `TokenVerificationCache.ensureVerified` (user token tekshiruvi)
/// olib tashlandi: u bron natijasiga ta'sir qilmas, faqat yopib bo'lmaydigan
/// yuklanish oynasida vaqt olardi. Bearer so'rovlar (profil) 401'da tokenni
/// interceptor orqali o'zi yangilaydi.
class BookingService with RequestConfig {
  ApiService apiService = ApiService();
  final AnalyticsService _analyticsService = AnalyticsService();

  Future<NetworkResponse> createBooking(
      {required String tid,
      required String clientEmail,
      required String firstName,
      required List<Map<String, dynamic>> passenger,
      required String clientPhoneNum,
      required BuildContext context}) async {
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);
    final normalizedPhone = normalizePhoneDigits(clientPhoneNum);
    final normalizedPassengers = passenger.map((p) {
      final copy = Map<String, dynamic>.from(p);
      final rawPhone = copy['phone'];
      if (rawPhone != null) {
        copy['phone'] = normalizePhoneDigits('$rawPhone');
      }
      return copy;
    }).toList();
    NetworkResponse response = await postRequest(
        headers: false,
        partnerToken: true,
        endPoint: EndPoints.avia_booking_create,
        params: {
          // Server xabarlari foydalanuvchi tilida kelsin (uz/ru/en).
          "lang": dataLang(),
          "tid": tid,
          "is_health_declaration_checked": 1,
          "accompanying_adult": [],
          // "bonus_card": "",
          // Backend faqat UZS va RUB'da bron qiladi — USD tanlangan bo'lsa
          // ham bron RUB'da yaratiladi (to'lov sahifasi bron valyutasini
          // ko'rsatadi).
          "currency": currencyProvider.currency.label == "UZS" ? "UZS" : "RUB",
          "client_email": clientEmail,
          "payer_name": firstName,
          "client_phone": normalizedPhone,
          "passengers": normalizedPassengers
        });
    if (response is NetworkSuccessResponse) {
      final data = response.data;
      final trId = data is Map ? data["tr_id"] : null;
      if (trId != null && '$trId'.isNotEmpty) {
        try {
          final bookingModel =
              BookingCreateModel.fromJson(Map<String, dynamic>.from(data));
          return NetworkSuccessResponse(data: bookingModel);
        } catch (e) {
          debugPrint('MySafarSdk: booking-create javobi o\'qilmadi ($e)');
        }
      }
      // `tr_id` yo'q (yoki javobni o'qib bo'lmadi): butun javob beriladi —
      // serverning o'z xabari bo'lsa getError() uni foydalanuvchi tilida
      // chiqaradi, bo'lmasa "Buyurtmalarim"ni tekshirish haqida xabar.
      return NetworkErrorResponse(
          error: data, errorType: ErrorType.bookingMissingTrId);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  partnerTickets() {}

  Future<NetworkResponse> confirmPayment({
    required String trId,
    required String otpToken,
    required int otp,
  }) async {
    NetworkResponse response = await postRequest(
        headers: false,
        partnerToken: true,
        endPoint: EndPoints.avia_payment_confirm,
        params: {"otp": otp, "otp_token": otpToken, "tr_id": trId});
    if (response is NetworkSuccessResponse) {
      // Track transaction paid + revenue
      final data = response.data;
      final order = data['data']?['book']?['order'];
      final billingNumber = order?['billing_number'];
      final revenue = _extractRevenue(data);
      if (billingNumber != null) {
        _analyticsService.trackTransactionPaid(
          trId: trId,
          billingNumber: billingNumber.toString(),
          amount: revenue.amount > 0 ? revenue.amount : null,
          currency: revenue.amount > 0 ? revenue.currency : null,
        );
      }
      if (revenue.amount > 0) {
        _analyticsService.trackRevenue(
          amount: revenue.amount,
          currency: revenue.currency,
          orderId: billingNumber?.toString(),
        );
      }

      return NetworkSuccessResponse(data: response.data);
    } else if (response is NetworkErrorResponse) {
      // Track failed payment
      _analyticsService.trackPaymentFailed(
        trId: trId,
        errorMessage: response.getError(),
        paymentMethod: 'card_otp',
      );
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  /// To'lov javobidan revenue uchun summa va valyutani ehtiyotkorlik bilan
  /// chiqaradi. Yo'l noto'g'ri/yo'q bo'lsa 0 qaytaradi (revenue yuborilmaydi).
  ({num amount, String currency}) _extractRevenue(dynamic data) {
    num total = 0;
    String currency = 'UZS';
    try {
      if (data is! Map) return (amount: total, currency: currency);
      final inner = data['data'];
      if (inner is! Map) return (amount: total, currency: currency);
      final book = inner['book'];
      if (book is! Map) return (amount: total, currency: currency);

      final order = book['order'];
      if (order is Map) {
        final details = order['passengers_price_details'];
        if (details is List) {
          for (final d in details) {
            if (d is Map) {
              final p = d['ticket_price'];
              if (p is num) total += p;
            }
          }
        }
      }

      final tickets = book['tickets'];
      if (tickets is List && tickets.isNotEmpty) {
        final first = tickets.first;
        if (first is Map) {
          final prov = first['provider'];
          if (prov is Map) {
            final c = prov['currency'];
            if (c is String && c.isNotEmpty) currency = c;
          }
        }
      }
    } catch (_) {}
    return (amount: total, currency: currency);
  }

  Future<NetworkResponse> confirmBooking(
      {required Map<String, dynamic> params}) async {
    NetworkResponse response = await postRequest(
        headers: false,
        partnerToken: true,
        endPoint: EndPoints.avia_booking_confirm,
        params: params);
    if (response is NetworkSuccessResponse) {
      return _confirmResult(response.data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.error, errorType: response.errorType);
    } else {
      return response;
    }
  }

  /// `booking-confirm` 200 javobi: `status: false` — xato. Butun javob
  /// beriladi — getError() `error.message.{uz|ru|en}` dan foydalanuvchi
  /// tilidagisini o'zi tanlaydi; shakl boshqacha bo'lsa ham yiqilmaydi.
  NetworkResponse _confirmResult(dynamic data) {
    if (data is! Map) {
      return NetworkErrorResponse(error: data, errorType: ErrorType.other);
    }
    if (data['status'] == false) {
      return NetworkErrorResponse(error: data);
    }
    return NetworkSuccessResponse(data: Map<String, dynamic>.from(data));
  }

  Future<NetworkResponse> getCardInfo({
    required String cardNumber,
  }) async {
    NetworkResponse response = await postRequest(
        retryable: true,
        headers: false,
        partnerToken: true,
        endPoint: EndPoints.get_card_info,
        params: {"card_number": cardNumber});

    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse(data: response.data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  Future<NetworkResponse> getTicketStatus({
    required String billingId,
  }) async {
    NetworkResponse response = await postRequest(
      retryable: true,
      headers: false,
      partnerToken: true,
      endPoint: "${EndPoints.avia_booking_status}/$billingId",
    );

    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse(data: response.data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  /// Mavjud to'lov turlarini oladi (`/get-payment-type`). Server
  /// `{"result": [ {id, name, is_active}, ... ]}` ko'rinishida qaytaradi;
  /// muvaffaqiyatda `List<Result>` beriladi.
  Future<NetworkResponse> getPaymentType() async {
    NetworkResponse response = await getRequest(
        endPoint: EndPoints.getPaymentType, partnerToken: true, headers: false);

    if (response is NetworkSuccessResponse) {
      final data = response.data;
      final List<Result> result;
      if (data is Map<String, dynamic>) {
        result = GetPaymentTypeModel.fromJson(data).result ?? <Result>[];
      } else if (data is List) {
        result = data
            .map((e) => Result.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        result = <Result>[];
      }
      return NetworkSuccessResponse(data: result);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  Future<NetworkResponse> getTicketedBookingInfo({
    required String billingId,
  }) async {
    NetworkResponse response = await postRequest(
      retryable: true,
      headers: false,
      partnerToken: true,
      endPoint: "${EndPoints.avia_ticketed_booking_info}/$billingId",
    );

    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse(data: response.data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  Future<NetworkResponse> centrumConfirmPayment({
    required String trId,
    required int otp,
  }) async {
    NetworkResponse response = await postRequest(
        headers: false,
        partnerToken: true,
        endPoint: "/centrum-payment-confirm",
        params: {"otp": otp, "tr_id": trId});
    if (response is NetworkSuccessResponse) {
      // Track transaction paid + revenue for Centrum
      final data = response.data;
      final order = data['data']?['book']?['order'];
      final billingNumber = order?['billing_number'];
      final revenue = _extractRevenue(data);
      if (billingNumber != null) {
        _analyticsService.trackTransactionPaid(
          trId: trId,
          billingNumber: billingNumber.toString(),
          amount: revenue.amount > 0 ? revenue.amount : null,
          currency: revenue.amount > 0 ? revenue.currency : null,
        );
      }
      if (revenue.amount > 0) {
        _analyticsService.trackRevenue(
          amount: revenue.amount,
          currency: revenue.currency,
          orderId: billingNumber?.toString(),
        );
      }
      return NetworkSuccessResponse(data: response.data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  Future<NetworkResponse> centrumConfirmBooking(
      {required Map<String, dynamic> params}) async {
    NetworkResponse response = await postRequest(
        headers: false,
        partnerToken: true,
        endPoint: "/centrum-payment-create",
        params: params);
    if (response is NetworkSuccessResponse) {
      return _confirmResult(response.data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.error, errorType: response.errorType);
    } else {
      return response;
    }
  }
}
