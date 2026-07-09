import 'dart:async' show unawaited;

import 'package:mysafar_sdk/src/core/config/dio_client.dart'
    show AuthMode, DioClient;
import 'package:mysafar_sdk/src/core/config/response_config.dart'
    show
        ErrorType,
        NetworkErrorResponse,
        NetworkResponse,
        NetworkSuccessResponse;
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart'
    show AnalyticsService;
import 'package:dio/dio.dart'
    show DioException, DioExceptionType, Options, Response;
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;

mixin RequestConfig<T> {

  bool get hasAccessToken => MySafarSdk.tokens.isLoggedIn;

  /// Resolves the auth strategy. Partner auth takes precedence over bearer,
  /// matching the previous behaviour.
  AuthMode _authMode({bool? headers, bool? partnerToken}) {
    if (partnerToken ?? false) return AuthMode.partner;
    if (headers ?? false) return AuthMode.bearer;
    return AuthMode.none;
  }

  Future<NetworkResponse> _send(
    String method,
    String endPoint, {
    Object? data,
    Map<String, dynamic>? query,
    required AuthMode authMode,
    String? contentType,
  }) async {
    try {
      final response = await DioClient.main.request(
        endPoint,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          extra: {
            'authMode': authMode,
            if (contentType != null) 'contentType': contentType,
          },
        ),
      );
      return _getResponse(response);
    } on DioException catch (e) {
      return _catchError(e);
    } catch (e) {
      // Dio bo'lmagan kutilmagan xatolik (JSON shakli, interceptor StateError,
      // socket va h.k.) — UI'ga uzatib yubormasdan xato holatiga aylantiramiz.
      return _unexpectedError(e, endPoint, method);
    }
  }

  Future<NetworkResponse> postRequest({
    final bool? headers,
    final Map<String, dynamic>? params,
    final bool? partnerToken,
    required String endPoint,
  }) {
    return _send('POST', endPoint,
        data: params,
        authMode: _authMode(headers: headers, partnerToken: partnerToken));
  }

  // get
  Future<NetworkResponse> getRequest({
    required final String endPoint,
    final bool? headers,
    final bool? partnerToken,
    final Map<String, dynamic>? params,
  }) {
    return _send('GET', endPoint,
        data: params,
        authMode: _authMode(headers: headers, partnerToken: partnerToken));
  }

  // patch
  Future<NetworkResponse> patchRequest({
    final bool? headers,
    final String? contentType,
    final bool? partnerToken,
    required final String endPoint,
    final T? params,
  }) {
    return _send('PATCH', endPoint,
        data: params,
        contentType: contentType,
        authMode: _authMode(headers: headers, partnerToken: partnerToken));
  }

  /// this method filters by status code and returns specific response
  NetworkResponse _getResponse(Response response) {
    switch (response.statusCode) {
      // success
      case 200:
      case 201:
      case 202:
      case 204:
        return NetworkSuccessResponse(data: response.data);

      case 400:
        return _errorResponse(response, ErrorType.badResponse_400);
      case 401:
        return _errorResponse(response, ErrorType.unAuthorized_401);
      case 403:
        return _errorResponse(response, ErrorType.forbidden_403);
      case 404:
        return _errorResponse(response, ErrorType.notFound_404);
      case 409:
        return _errorResponse(response, ErrorType.conflict_409);
      case 413:
        return _errorResponse(response, ErrorType.conflict_409);

      case 500:
        return _errorResponse(response, ErrorType.internalServer_500);
      case 502:
        return _errorResponse(response, ErrorType.badGateway_502);
      case 503:
        return _errorResponse(response, ErrorType.serviceUnavailable_503);
      case 504:
        return _errorResponse(response, ErrorType.gatewayTimeout_504);
      default:
        return _errorResponse(response, ErrorType.dio_error);
    }
  }

  ///  filters dio exception by type
  NetworkResponse _catchError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return _dioErrorResponse(
            e, ErrorType.connectTimeout, "Connect timeout");
      case DioExceptionType.receiveTimeout:
        return _dioErrorResponse(
            e, ErrorType.receiveTimeout, "Receive timeout");

      case DioExceptionType.sendTimeout:
        return _dioErrorResponse(e, ErrorType.sendTimeout, "Send timeout");
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response != null) {
          // status code'li xatolik — _getResponse o'zi event yuboradi.
          return _getResponse(response);
        }
        return _dioErrorResponse(e, ErrorType.dio_error, "Bad response");
      case DioExceptionType.connectionError:
        return _dioErrorResponse(
            e, ErrorType.connectionError, "No connection");
      case DioExceptionType.unknown:
        return _dioErrorResponse(
            e, ErrorType.connectionError, "No connection");

      default:
        return _dioErrorResponse(e, ErrorType.other, "Something went wrong");
    }
  }

  /// HTTP status kodli xatolik uchun [NetworkErrorResponse] yaratadi va
  /// analyticsga `api_error` eventini yuboradi (qaysi ekran, endpoint, kod).
  NetworkErrorResponse _errorResponse(Response response, ErrorType errorType) {
    final options = response.requestOptions;
    unawaited(AnalyticsService().trackApiError(
      endpoint: options.path,
      method: options.method,
      statusCode: response.statusCode,
      errorType: errorType.name,
      error: response.data,
    ));
    return NetworkErrorResponse(
      error: response.data is Map<String, dynamic>
          ? response.data
          : "${response.statusMessage}",
      errorType: errorType,
    );
  }

  /// Dio darajasidagi xatolik (timeout, ulanish yo'q va h.k.) uchun
  /// [NetworkErrorResponse] yaratadi va analyticsga `api_error` eventini yuboradi.
  NetworkErrorResponse _dioErrorResponse(
      DioException e, ErrorType errorType, String message) {
    final options = e.requestOptions;
    unawaited(AnalyticsService().trackApiError(
      endpoint: options.path,
      method: options.method,
      statusCode: e.response?.statusCode,
      errorType: errorType.name,
      error: e.message ?? message,
    ));
    return NetworkErrorResponse(error: message, errorType: errorType);
  }

  /*
    SKOTE REQUESTS
  */
  Future<NetworkResponse> get({
    final Map<String, dynamic>? params,
    final Map<String, dynamic>? query,
    required String endPoint,
  }) async {
    try {
      final response = await DioClient.skote.get(
        endPoint,
        data: params,
        queryParameters: query,
      );
      return _getResponse(response);
    } on DioException catch (e) {
      return _catchError(e);
    } catch (e) {
      return _unexpectedError(e, endPoint, 'GET');
    }
  }

  Future<NetworkResponse> post({
    final String? contentType,
    final Map<String, dynamic>? query,
    Object? params,
    required String endPoint,
  }) async {
    try {
      final response = await DioClient.skote.post(
        endPoint,
        data: params,
        queryParameters: query,
        options: Options(
          extra: {if (contentType != null) 'contentType': contentType},
        ),
      );
      return _getResponse(response);
    } on DioException catch (e) {
      return _catchError(e);
    } catch (e) {
      return _unexpectedError(e, endPoint, 'POST');
    }
  }

  /// Dio bo'lmagan, kutilmagan xatolik (masalan javob JSON shakli noto'g'ri,
  /// interceptor `StateError`, yoki socket muammosi) uchun [NetworkErrorResponse]
  /// yaratadi va analyticsga bir marta `api_error` yuboradi — bu xatoliklar
  /// UI'gача uzoqqa ketib, ilovani yiqitmasligi yoki AppMetrica'da "olinmagan
  /// xato" bo'lib qolmasligi uchun.
  NetworkResponse _unexpectedError(Object e, String endPoint, String method) {
    unawaited(AnalyticsService().trackApiError(
      endpoint: endPoint,
      method: method,
      errorType: ErrorType.other.name,
      error: e,
    ));
    return NetworkErrorResponse(
        error: "Something went wrong", errorType: ErrorType.other);
  }
}
