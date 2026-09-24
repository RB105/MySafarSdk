import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'package:mysafar_sdk/src/service/payment/sensitive_log.dart';

class AddCardService with RequestConfig {
  Future<NetworkResponse> getCardInfo({
    required String cardNumber,
  }) async {
    // Karta ma'lumotlari faqat debug'da va niqoblangan (№63).
    SensitiveLog.debug(
        'get-card-info card=${SensitiveLog.maskTail(cardNumber)}');

    final response = await postRequest(
      retryable: true,
      headers: false,
      partnerToken: true,
      endPoint: EndPoints.get_card_info,
      params: {"card_number": cardNumber},
    );

    try {
      if (response is NetworkSuccessResponse) {
        return NetworkSuccessResponse(data: response.data);
      }
      return response;
    } catch (e) {
      debugPrint('MySafarSdk: add-card xatosi (${e.runtimeType})');
      return response;
    }
  }

  Future<NetworkResponse> sendCardOtp({
    required String cardNumber,
    required String expire,
    required String cardType,
    required String phone,
  }) async {
    SensitiveLog.debug('send-card-otp card=${SensitiveLog.maskTail(cardNumber)} '
        'expire=${SensitiveLog.hide(expire)} type=$cardType '
        'phone=${SensitiveLog.maskTail(phone)}');

    final response = await postRequest(
      partnerToken: true,
      endPoint: EndPoints.autopaySendCardOtp,
      params: {
        "card_number": cardNumber,
        "expire": expire,
        "card_type": cardType,
        "phone": phone,
      },
    );

    try {
      if (response is NetworkSuccessResponse) {
        return NetworkSuccessResponse(data: response.data);
      }
      return response;
    } catch (e) {
      debugPrint('MySafarSdk: add-card xatosi (${e.runtimeType})');
      return response;
    }
  }

  Future<NetworkResponse> verifyCardOtp({
    required String id,
    required String code,
    required String cardType,
  }) async {
    SensitiveLog.debug(
        'verify-card-otp id=$id code=${SensitiveLog.hide(code)} type=$cardType');

    final response = await postRequest(
      partnerToken: true,
      endPoint: EndPoints.autopayVerifyCardOtp,
      params: {
        "id": id,
        "code": code,
        "card_type": cardType,
      },
    );

    try {
      if (response is NetworkSuccessResponse) {
        return NetworkSuccessResponse(data: response.data);
      }
      return response;
    } catch (e) {
      debugPrint('MySafarSdk: add-card xatosi (${e.runtimeType})');
      return response;
    }
  }

  Future<NetworkResponse> linkCard({
    required String cardUuid,
    required int contractId,
  }) async {
    SensitiveLog.debug('card-link contract=$contractId');

    final response = await postRequest(
      partnerToken: true,
      endPoint: EndPoints.autopayCardLink,
      params: {
        "card_uuid": cardUuid,
        "contract_id": contractId,
      },
    );

    try {
      if (response is NetworkSuccessResponse) {
        return NetworkSuccessResponse(data: response.data);
      }
      return response;
    } catch (e) {
      debugPrint('MySafarSdk: add-card xatosi (${e.runtimeType})');
      return response;
    }
  }
}
