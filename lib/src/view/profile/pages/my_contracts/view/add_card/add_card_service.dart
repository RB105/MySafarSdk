import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';

class AddCardService with RequestConfig {
  Future<NetworkResponse> getCardInfo({
    required String cardNumber,
  }) async {
    debugPrint("get-card-info card=$cardNumber");

    final response = await postRequest(
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
    } on Exception catch (e) {
      debugPrint(e.toString());
      return response;
    }
  }

  Future<NetworkResponse> sendCardOtp({
    required String cardNumber,
    required String expire,
    required String cardType,
    required String phone,
  }) async {
    debugPrint(
        "send-card-otp card=$cardNumber expire=$expire type=$cardType phone=$phone");

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
    } on Exception catch (e) {
      debugPrint(e.toString());
      return response;
    }
  }

  Future<NetworkResponse> verifyCardOtp({
    required String id,
    required String code,
    required String cardType,
  }) async {
    debugPrint("verify-card-otp id=$id code=$code type=$cardType");

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
    } on Exception catch (e) {
      debugPrint(e.toString());
      return response;
    }
  }

  Future<NetworkResponse> linkCard({
    required String cardUuid,
    required int contractId,
  }) async {
    debugPrint("card-link uuid=$cardUuid contract=$contractId");

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
    } on Exception catch (e) {
      debugPrint(e.toString());
      return response;
    }
  }
}
