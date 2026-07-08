
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:mysafar_sdk/src/core/config/request_config.dart';
import 'package:mysafar_sdk/src/core/config/response_config.dart';
import 'package:mysafar_sdk/src/core/constants/end_points.dart';
import 'package:get_storage/get_storage.dart' show GetStorage;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

class AuthService with RequestConfig {
  /// GetStorage instance
  final GetStorage _db = sdkStorage();

  /// Analytics service instance
  final AnalyticsService _analyticsService = AnalyticsService();

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

  /// Host app foydalanuvchisini telefon raqami bilan tez (parolsiz/OTPsiz)
  /// ro'yxatdan o'tkazadi — embed stsenariysi uchun. Muvaffaqiyatda tokenlar
  /// saqlanadi va sessiya ochiladi.
  Future<NetworkResponse> webRegister({required String phoneNumber}) async {
    final response = await postRequest(
        endPoint: EndPoints.auth_web_register,
        params: {"phone_number": phoneNumber});

    if (response is NetworkSuccessResponse) {
      await MySafarSdk.tokens.saveTokens(
        access: '${response.data["jwt_token"]["access"]}',
        refresh: '${response.data["jwt_token"]["refresh"]}',
      );
      MySafarSdk.callbacks.onLoggedIn?.call();

      _analyticsService.trackUserRegisteredPhone(phoneNumber: phoneNumber);
      _analyticsService.setUser(userId: phoneNumber, attributes: {
        'auth_provider': 'web_register',
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
