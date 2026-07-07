
import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
class BanCheckAndVisaService  with RequestConfig{
  Future<NetworkResponse> getUzBanChek(Map<String,dynamic> params) async {
    final response = await postRequest(
      partnerToken: true,
        endPoint:EndPoints.egov,
        params:params
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
  Future<NetworkResponse> myIdSessionId(Map<String,dynamic> params) async {
    final response = await postRequest(
        partnerToken: true,
        endPoint:EndPoints.myIdSession,
        params:params
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

  Future<NetworkResponse> getMyIdUserInfo({
    required String code,
    required String phoneNumber,
  }) async {
    final response = await getRequest(
      partnerToken: true,
      endPoint: EndPoints.myIdUserInfo(code, phoneNumber),
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