import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show NetworkErrorResponse, NetworkResponse, NetworkSuccessResponse;
import 'package:mysafar_sdk/src/core/constants/end_points.dart' show EndPoints;
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'package:mysafar_sdk/src/core/enum/currency.dart';
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart'
    show CurrencyProvider;
import 'package:mysafar_sdk/src/model/remote/booking/booking_create_model.dart';
import 'package:mysafar_sdk/src/model/remote/booking/payment_type_model.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/api_service.dart';
import 'package:mysafar_sdk/src/service/token_verification_cache.dart';
import 'package:provider/provider.dart' show Provider;

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
    await TokenVerificationCache.ensureVerified(apiService);
    NetworkResponse response = await postRequest(
        headers: false,
        partnerToken: true,
        endPoint: EndPoints.avia_booking_create,
        params: {
          "lang": "en",
          "tid": tid,
          "is_health_declaration_checked": 1,
          "accompanying_adult": [],
          // "bonus_card": "",
          "currency": currencyProvider.currency.label == "UZS" ? "UZS" : "RUB",
          "client_email": clientEmail,
          "payer_name": firstName,
          "client_phone": clientPhoneNum,
          "passengers": passenger
        });
    if (response is NetworkSuccessResponse) {
      if (response.data["tr_id"] != null) {
        final bookingModel = BookingCreateModel.fromJson(response.data);
        return NetworkSuccessResponse(data: bookingModel);
      } else {
        return NetworkErrorResponse(error: response.data["data"]["message"]);
      }
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  Future<NetworkResponse> confirmPayment({
    required String trId,
    required String otpToken,
    required int otp,
  }) async {
    await TokenVerificationCache.ensureVerified(apiService);
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
    await TokenVerificationCache.ensureVerified(apiService);
    NetworkResponse response = await postRequest(
        headers: false,
        partnerToken: true,
        endPoint: EndPoints.avia_booking_confirm,
        params: params);
    if (response is NetworkSuccessResponse) {
      if (response.data['status'] != null && response.data['status'] == false) {
        return NetworkErrorResponse(
            error: response.data["error"]["message"]["uz"]);
      } else {
        return NetworkSuccessResponse(data: response.data);
      }
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.error, errorType: response.errorType);
    } else {
      return response;
    }
  }

  Future<NetworkResponse> getCardInfo({
    required String cardNumber,
  }) async {
    await TokenVerificationCache.ensureVerified(apiService);
    NetworkResponse response = await postRequest(
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
    await TokenVerificationCache.ensureVerified(apiService);
    NetworkResponse response = await postRequest(
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
    await TokenVerificationCache.ensureVerified(apiService);
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
    await TokenVerificationCache.ensureVerified(apiService);
    NetworkResponse response = await postRequest(
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
    await TokenVerificationCache.ensureVerified(apiService);
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
    await TokenVerificationCache.ensureVerified(apiService);
    NetworkResponse response = await postRequest(
        headers: false,
        partnerToken: true,
        endPoint: "/centrum-payment-create",
        params: params);
    if (response is NetworkSuccessResponse) {
      if (response.data['status'] != null && response.data['status'] == false) {
        return NetworkErrorResponse(
            error: response.data["error"]["message"]["uz"]);
      } else {
        return NetworkSuccessResponse(data: response.data);
      }
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.error, errorType: response.errorType);
    } else {
      return response;
    }
  }
}
