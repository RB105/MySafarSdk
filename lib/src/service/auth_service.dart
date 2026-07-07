import 'dart:io' show Platform;

import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart' show GetStorage;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';

class AuthService with RequestConfig {
  /// GetStorage instance
  final GetStorage _db = GetStorage();

  /// Analytics service instance
  final AnalyticsService _analyticsService = AnalyticsService();

  Future<NetworkResponse> googleAuth({
    required String token,
    required String email,
  }) async {
    final response = await postRequest(
        partnerToken: true,
        endPoint: EndPoints.google_auth,
        params: {
          "token": token,
          "email": email,
          "type": Platform.isIOS ? "mobile-ios" : "mobile-android"
        });

    if (response is NetworkSuccessResponse) {
      await MySafarSdk.tokens.saveTokens(
        access: '${response.data["jwt_token"]["access"]}',
        refresh: '${response.data["jwt_token"]["refresh"]}',
      );
      MySafarSdk.callbacks.onLoggedIn?.call();

      // Set FCM reg_id after successful auth
      setRegId();

      // Track Google registration/login analytics
      _analyticsService.trackUserLoggedInGoogle(email: email);
      _analyticsService.setUser(userId: email, attributes: {
        'auth_provider': 'google',
        'lang': _db.read<String>('lang') ?? 'uz',
      });

      return NetworkSuccessResponse(data: response.data);
    }
    return response;
  }

  Future<NetworkResponse> telegramAuth({
    required String token,
  }) async {
    final response = await postRequest(
        endPoint: EndPoints.telegram_auth,
        partnerToken: true,
        params: {
          "token": token,
        });

    if (response is NetworkSuccessResponse) {
      await MySafarSdk.tokens.saveTokens(
        access: '${response.data["jwt_token"]["access"]}',
        refresh: '${response.data["jwt_token"]["refresh"]}',
      );
      MySafarSdk.callbacks.onLoggedIn?.call();

      setRegId();

      return NetworkSuccessResponse(data: response.data);
    }
    return response;
  }

  //phone number register
  Future<NetworkResponse> register({
    required String phoneNum,
    required String password,
    String? name,
    String? lastName,
  }) async {
    final response =
        await postRequest(endPoint: EndPoints.auth_phone_register, params: {
      "phone_number": phoneNum,
      "password": password,
      "password2": password,
      "firstname": name ?? "",
      "lastname": lastName ?? ""
    });
    if (response is NetworkSuccessResponse) {
      await MySafarSdk.tokens.saveTokens(
        access: '${response.data["jwt_token"]["access"]}',
        refresh: '${response.data["jwt_token"]["refresh"]}',
      );
      MySafarSdk.callbacks.onLoggedIn?.call();

      // Set FCM reg_id after successful auth
      setRegId();

      // Track phone registration analytics
      _analyticsService.trackUserRegisteredPhone(phoneNumber: phoneNum);
      _analyticsService.setUser(userId: phoneNum, attributes: {
        'auth_provider': 'phone',
        'registered': true,
        'lang': _db.read<String>('lang') ?? 'uz',
      });

      return NetworkSuccessResponse(data: response.data);
    }
    return response;
  }

  // Future<NetworkResponse> login({
  //   required String phoneNum,
  //   required String password,
  // }) async {
  //   final response = await postRequest(
  //       endPoint: EndPoints.auth_phone_login,
  //       params: {"phone": phoneNum, "password": password});
  //   if (response is NetworkSuccessResponse) {
  //     _db.write("refresh_token", response.data["jwt_token"]["refresh"]);
  //     _db.write("access_token", response.data["jwt_token"]["access"]);
  //
  //     return NetworkSuccessResponse(data: response.data);
  //   }
  //
  //   return response;
  // }

  Future<NetworkResponse> setPassword({required String password}) async {
    final NetworkResponse response = await patchRequest(
        headers: true,
        endPoint: EndPoints.auth_set_password,
        params: {"password": password, "password2": password});
    if (response is NetworkSuccessResponse) {
      return const NetworkSuccessResponse(data: true);
    }

    return response;
  }

  Future<NetworkResponse> deleteUser() async {
    final response =
        await postRequest(endPoint: EndPoints.auth_user_delete, headers: true);

    return response;
  }

  /// set-regid for FCM
  Future<void> setRegId() async {
    if (!hasAccessToken) {
      if (kDebugMode) {
        debugPrint('setRegId skipped: user not authorized');
      }
      return;
    }

    String? regId = _db.read('regId');

    if (regId == null || regId.isEmpty) {
      try {
        regId = await MySafarSdk.callbacks.getPushToken?.call();
        if (regId != null) {
          _db.write('regId', regId);
          if (kDebugMode) {
            debugPrint('regId fetched from host push provider');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error getting push token: $e');
        }
      }
    }

    if (regId == null || regId.isEmpty) {
      if (kDebugMode) {
        debugPrint('regId is still null, skipping setRegId');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('regId is available');
    }
    await postRequest(
        headers: true,
        endPoint: EndPoints.auth_set_reg_id,
        params: {"reg_id": regId}).then(
      (value) {
        if (kDebugMode && value is NetworkSuccessResponse) {
          debugPrint('Success in reg id SET');
        }
      },
    );
  }

  Future sendOtp(String phone) async {
    final response = await postRequest(
        endPoint: EndPoints.auth_send_otp, params: {"phone": phone});

    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse(data: response.data['otp_token']);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }

    return response;
  }

  Future verifyOtp(
      {required String phone,
      required String token,
      required String otp}) async {
    final response = await postRequest(
        endPoint: EndPoints.auth_verify_otp,
        params: {"phone": phone, "otp_token": token, "otp": otp});

    if (response is NetworkSuccessResponse) {
      await MySafarSdk.tokens.saveTokens(
        access: '${response.data["jwt_token"]["access"]}',
        refresh: '${response.data["jwt_token"]["refresh"]}',
      );
      MySafarSdk.callbacks.onLoggedIn?.call();

      // Set FCM reg_id after successful auth
      setRegId();

      // Track phone login analytics
      _analyticsService.trackUserLoggedInPhone(phoneNumber: phone);
      _analyticsService.setUser(userId: phone, attributes: {
        'auth_provider': 'phone',
        'lang': _db.read<String>('lang') ?? 'uz',
      });

      return NetworkSuccessResponse(data: response.data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }

    return response;
  }
}
