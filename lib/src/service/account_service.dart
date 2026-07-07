import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'package:mysafar_sdk/src/core/tools/project_utils.dart';
import 'package:mysafar_sdk/src/model/remote/profile/cheque_model.dart';

import 'package:mysafar_sdk/src/model/remote/profile/profile_model.dart';

class AccountService with RequestConfig {
  // get profile1
  Future<NetworkResponse> getProfile() async {
    NetworkResponse response =
        await getRequest(endPoint: EndPoints.profile, headers: true);

    if (response is NetworkSuccessResponse) {
      final profileModel = ProfileModel.fromJson(response.data);
      return NetworkSuccessResponse(data: profileModel);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }
    return response;
  }

  Future<NetworkResponse> setPassword(
      {required String password, required String password2}) async {
    NetworkResponse response = await patchRequest(
        endPoint: EndPoints.auth_set_password,
        headers: true,
        params: {"password": password, "password2": password2});

    if (response is NetworkSuccessResponse) {
      return const NetworkSuccessResponse(data: true);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }

    return response;
  }

  Future<NetworkResponse> checkAppVersion() async {
    final versionCode = await ProjectUtils.getVersionCode();
    NetworkResponse response =
        await postRequest(endPoint: EndPoints.check_version_platform, params: {
      "version_code": versionCode,
      "platform_type": Platform.isAndroid ? "ANDROID" : "IOS"
    });

    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse(data: response.data);
    }
    return response;
  }

  Future<NetworkResponse> updateProfile(FormData formData) async {
    NetworkResponse response = await patchRequest(
        contentType: "multipart/form-data",
        headers: true,
        endPoint: EndPoints.updateProfile,
        params: formData);

    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse(data: response.data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }
    return response;
  }

  Future<NetworkResponse> getOfdCheques() async {
    final response =
        await getRequest(endPoint: EndPoints.user_ofd_cheques, headers: true);

    if (response is NetworkSuccessResponse) {
      if (response.data is List && (response.data as List).isEmpty) {
        return NetworkErrorResponse(
            error: "empty", errorType: ErrorType.emptyResponse);
      }

      final result = (response.data as List)
          .map(
            (e) => ChequeModel.fromJson(e),
          )
          .toList();
      return NetworkSuccessResponse(data: result);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }

    return response;
  }
}
