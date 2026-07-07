import 'package:mysafar_sdk/src/service/api_service.dart';
import 'package:mysafar_sdk/src/service/token_verification_cache.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class ProfileService with RequestConfig {
  ApiService apiService = ApiService();

  Future<NetworkResponse> getProfileData() async {
    if (!hasAccessToken) {
      return NetworkErrorResponse(
          error: 'unauthorized', errorType: ErrorType.unAuthorized_401);
    }
    await TokenVerificationCache.ensureVerified(apiService);
    final NetworkResponse response =
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

  Future<NetworkResponse> updateProfileData(ProfileModel profileModel) async {
    await TokenVerificationCache.ensureVerified(apiService);
    final NetworkResponse response = await patchRequest(
        endPoint: EndPoints.updateProfile,
        contentType: "multipart/form-data",
        params: profileModel.toFormData(),
        headers: true);
    if (response is NetworkSuccessResponse) {
      final profileModel = ProfileModel.fromJson(response.data);
      return NetworkSuccessResponse(data: profileModel);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }
    return response;
  }

  Future<NetworkResponse> getTickets() async {
    if (!hasAccessToken) {
      return NetworkErrorResponse(
          error: 'unauthorized', errorType: ErrorType.unAuthorized_401);
    }
    await TokenVerificationCache.ensureVerified(apiService);
    final NetworkResponse response = await getRequest(
        endPoint: EndPoints.user_confirmed_tickets, headers: true);
    if (response is NetworkSuccessResponse) {
      // Xom JSON ro'yxatini qaytaramiz — cubit uni ham keshlaydi, ham parse
      // qiladi. Bu keshni serverdagi javob bilan bir xil saqlaydi (model
      // toJson to'liq bo'lmagani uchun round-trip'da maydonlar yo'qolmaydi).
      // Javob Map bo'lmasa (204, bo'sh yoki kutilmagan format) — bo'sh ro'yxat.
      final body = response.data;
      final List rawTickets =
          (body is Map ? body['confirmed_tickets'] : null) as List? ?? const [];
      return NetworkSuccessResponse(data: rawTickets);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }
    return response;
  }

  Future<NetworkResponse> getUserDate() async {
    await TokenVerificationCache.ensureVerified(apiService);
    final NetworkResponse response =
        await getRequest(endPoint: EndPoints.get_user_date, headers: true);
    if (response is NetworkSuccessResponse) {
      return NetworkSuccessResponse(data: response.data);
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    }
    return response;
  }

  Future<NetworkResponse> createUser(
      {required Map<String, dynamic> params}) async {
    await TokenVerificationCache.ensureVerified(apiService);
    final NetworkResponse response = await postRequest(
        params: params, endPoint: EndPoints.create_user_date, headers: true);
    if (response is NetworkSuccessResponse) {
      if (response.data["success"]) {
        return NetworkSuccessResponse(data: response.data);
      } else {
        return response;
      }
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  Future<NetworkResponse> updateUserDate(
      {required Map<String, dynamic> params, required int id}) async {
    await TokenVerificationCache.ensureVerified(apiService);
    final NetworkResponse response = await postRequest(
        params: params,
        endPoint: "${EndPoints.update_user_date}/$id/",
        headers: true);
    if (response is NetworkSuccessResponse) {
      if (response.data["success"]) {
        return NetworkSuccessResponse(data: response.data);
      } else {
        return response;
      }
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }

  Future<NetworkResponse> deleteUserDate({required int id}) async {
    await TokenVerificationCache.ensureVerified(apiService);
    final NetworkResponse response = await postRequest(
        endPoint: "${EndPoints.delete_user_date}/$id/", headers: true);
    if (response is NetworkSuccessResponse) {
      if (response.data["success"]) {
        return NetworkSuccessResponse(data: response.data);
      } else {
        return response;
      }
    } else if (response is NetworkErrorResponse) {
      return NetworkErrorResponse(
          error: response.getError(), errorType: response.errorType);
    } else {
      return response;
    }
  }
}
