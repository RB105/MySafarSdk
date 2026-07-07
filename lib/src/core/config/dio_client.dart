import 'dart:async' show Completer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:get_storage/get_storage.dart' show GetStorage;
import 'package:mysafar_sdk/src/core/config/app_config.dart' show AppConfig;
import 'package:mysafar_sdk/src/core/constants/end_points.dart' show EndPoints;

/// Auth strategies a request can use.
enum AuthMode { none, bearer, partner }

bool _validateStatus(int? code) => code != null && code >= 200 && code < 300;

BaseOptions _baseOptions() => BaseOptions(
      // Reduced from 120s. Long enough for slow payment/PDF responses,
      // short enough to fail fast on dead connections.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 90),
      validateStatus: _validateStatus,
      receiveDataWhenStatusError: true,
    );

/// Holds the shared, long-lived [Dio] instances. Reusing one [Dio] per backend
/// keeps the underlying HTTP connection pool alive (keep-alive / TCP+TLS reuse),
/// instead of allocating a brand-new client — and a fresh handshake — on every
/// request as the previous implementation did.
class DioClient {
  DioClient._();

  /// Main backend (`BASE_URL`). Handles bearer/partner auth and 401 refresh.
  static final Dio main = Dio(_baseOptions())
    ..interceptors.add(_MainAuthInterceptor());

  /// Skote backend (`SKOTE_BASE_URL`). No auth header.
  static final Dio skote = Dio(_baseOptions())
    ..interceptors.add(_SkoteInterceptor());
}

/// Refreshes the access token at most once at a time. Concurrent 401s share a
/// single in-flight refresh (via a [Completer]) instead of each firing its own
/// refresh call, which previously caused redundant requests and random logouts.
class TokenManager {
  TokenManager._();

  static final GetStorage _db = GetStorage();
  static Completer<bool>? _inFlight;

  static Future<bool> refresh() {
    final existing = _inFlight;
    if (existing != null) return existing.future;

    final completer = _inFlight = Completer<bool>();
    _doRefresh().then((ok) {
      _inFlight = null;
      completer.complete(ok);
    }).catchError((_) {
      _inFlight = null;
      completer.complete(false);
    });
    return completer.future;
  }

  static Future<bool> _doRefresh() async {
    final refreshToken = _db.read('refresh_token');
    if (refreshToken == null || refreshToken.toString().isEmpty) return false;

    await AppConfig.ensureLoaded();
    if (AppConfig.baseUrl.isEmpty) return false;

    // Bare client with no interceptor, so a 401 here cannot recurse.
    final dio = Dio(_baseOptions()..baseUrl = AppConfig.baseUrl);
    try {
      final response = await dio.post(
        EndPoints.api_v1_token_refresh,
        data: {'refresh': '$refreshToken'},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }),
      );
      final access = response.data is Map ? response.data['access'] : null;
      if (response.statusCode == 200 && access != null) {
        _db.write('access_token', '$access');
        return true;
      }
    } on DioException {
      return false;
    } finally {
      dio.close();
    }
    return false;
  }
}

class _MainAuthInterceptor extends Interceptor {
  final GetStorage _db = GetStorage();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (AppConfig.baseUrl.isEmpty) {
      await AppConfig.ensureLoaded();
    }
    if (AppConfig.baseUrl.isEmpty) {
      handler.reject(DioException(
        requestOptions: options,
        error: StateError('BASE_URL is not configured'),
        type: DioExceptionType.unknown,
      ));
      return;
    }

    options.baseUrl = AppConfig.baseUrl;

    final mode = options.extra['authMode'] as AuthMode? ?? AuthMode.none;
    final contentType = options.extra['contentType'] as String?;

    options.headers['Content-Type'] = contentType ?? 'application/json';
    options.headers['Accept'] = 'application/json';

    if (mode == AuthMode.partner) {
      if (!AppConfig.hasValidPartnerToken) {
        handler.reject(DioException(
          requestOptions: options,
          error: StateError('PARTNER_TOKEN is not configured'),
          type: DioExceptionType.unknown,
        ));
        return;
      }
      options.headers['Authorization'] = 'Token ${AppConfig.partnerToken}';
    } else if (mode == AuthMode.bearer) {
      final token = _db.read('access_token') ?? '';
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (kDebugMode) {
      debugPrint('\nRequest(method: ${options.method}, url: ${options.uri})');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final mode = err.requestOptions.extra['authMode'] as AuthMode? ?? AuthMode.none;
    final alreadyRetried = err.requestOptions.extra['authRetry'] == true;
    final token = _db.read<String>('access_token') ?? '';

    if (mode == AuthMode.bearer &&
        !alreadyRetried &&
        err.response?.statusCode == 401 &&
        token.isNotEmpty) {
      final refreshed = await TokenManager.refresh();
      if (refreshed) {
        try {
          final options = err.requestOptions..extra['authRetry'] = true;
          handler.resolve(await DioClient.main.fetch(options));
          return;
        } on DioException catch (e) {
          handler.next(e);
          return;
        }
      }
    }

    if (kDebugMode) {
      debugPrint('\nNetwork error: ${err.type} ${err.response?.statusCode}');
    }
    handler.next(err);
  }
}

class _SkoteInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (AppConfig.skoteBaseUrl.isEmpty) {
      await AppConfig.ensureLoaded();
    }
    if (AppConfig.skoteBaseUrl.isEmpty) {
      handler.reject(DioException(
        requestOptions: options,
        error: StateError('SKOTE_BASE_URL is not configured'),
        type: DioExceptionType.unknown,
      ));
      return;
    }

    options.baseUrl = AppConfig.skoteBaseUrl;
    final contentType = options.extra['contentType'] as String?;
    options.headers['Content-Type'] = contentType ?? 'application/json';
    options.headers['Accept'] = 'application/json';

    if (kDebugMode) {
      debugPrint('\nRequest(method: ${options.method}, url: ${options.uri})');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
          'Response: ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('\nNetwork error: ${err.type} ${err.response?.statusCode}');
    }
    handler.next(err);
  }
}
