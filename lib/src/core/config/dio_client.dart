import 'dart:async' show Completer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
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

  /// Main backend (`BASE_URL`). Bearer/partner auth + 401 refresh +
  /// 502/503/504 va qisqa tarmoq uzilishida retry.
  static final Dio main = Dio(_baseOptions())
    ..interceptors.addAll([
      _RetryInterceptor(),
      _MainAuthInterceptor(),
    ]);

  /// Skote backend (`SKOTE_BASE_URL`). No auth header.
  static final Dio skote = Dio(_baseOptions())
    ..interceptors.addAll([
      _RetryInterceptor(),
      _SkoteInterceptor(),
    ]);

  /// Fayl yuklash (PDF va h.k.) — uzun timeout, auth yo'q.
  static final Dio download = Dio(_baseOptions()
    ..connectTimeout = const Duration(seconds: 60)
    ..receiveTimeout = const Duration(seconds: 120));

  /// Umumiy download yordamchisi — bitta client orqali.
  static Future<Response<dynamic>> downloadFile(
    String url,
    String savePath, {
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) {
    return download.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

/// 502/503/504 (va qisqa tarmoq uzilishi) uchun engil retry — max 2 marta,
/// exponential backoff. Bekor qilingan so'rov va `skipRetry` qayta yuborilmaydi.
class _RetryInterceptor extends Interceptor {
  static const int _maxRetries = 2;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = (extra['retryCount'] as int?) ?? 0;
    final skipRetry = extra['skipRetry'] == true;

    if (skipRetry || retryCount >= _maxRetries || !_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final next = retryCount + 1;
    err.requestOptions.extra['retryCount'] = next;

    final delayMs = 300 * next * next; // 300ms, 1200ms
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    // Kutish paytida so'rov bekor qilingan bo'lsa — qayta yubormaymiz.
    if (err.requestOptions.cancelToken?.isCancelled ?? false) {
      handler.next(err);
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'Retry $next/$_maxRetries: ${err.requestOptions.method} '
        '${err.requestOptions.uri} (${err.response?.statusCode ?? err.type})',
      );
    }

    try {
      // Auth interceptor zanjiri saqlansin deb o'sha client orqali fetch.
      final dio =
          err.requestOptions.extra['dioClient'] as Dio? ?? DioClient.main;
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.cancel) return false;
    final code = err.response?.statusCode;
    if (code == 502 || code == 503 || code == 504) return true;
    // Qisqa tarmoq uzilishi — qayta urinish foydali.
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      return true;
    }
    return false;
  }
}

/// Refreshes the access token at most once at a time. Concurrent 401s share a
/// single in-flight refresh (via a [Completer]) instead of each firing its own
/// refresh call, which previously caused redundant requests and random logouts.
class TokenManager {
  TokenManager._();

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
    final refreshToken = MySafarSdk.tokens.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    await AppConfig.ensureLoaded();
    if (AppConfig.baseUrl.isEmpty) return false;

    // Bare client with no interceptor, so a 401 here cannot recurse.
    final dio = Dio(_baseOptions()..baseUrl = AppConfig.baseUrl);
    var refreshed = false;
    try {
      final response = await dio.post(
        EndPoints.api_v1_token_refresh,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          extra: {'skipRetry': true},
        ),
      );
      final access = response.data is Map ? response.data['access'] : null;
      if (response.statusCode == 200 && access != null) {
        await MySafarSdk.tokens.saveAccess('$access');
        refreshed = true;
      }
    } on DioException {
      refreshed = false;
    } finally {
      dio.close();
    }
    if (!refreshed) {
      // Sessiya uzil-kesil tugadi — host o'z login oqimini ko'rsatishi mumkin.
      MySafarSdk.callbacks.onAuthRequired?.call();
    }
    return refreshed;
  }
}

class _MainAuthInterceptor extends Interceptor {
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
    // Retry interceptor qaysi Dio orqali qayta yuborishni bilsin.
    options.extra['dioClient'] = DioClient.main;

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
      final token = MySafarSdk.tokens.accessToken ?? '';
      // Bo'sh "Bearer " yubormaymiz — serverga ketmasdan aniq 401 qaytadi.
      if (token.isEmpty) {
        handler.reject(DioException(
          requestOptions: options,
          error: StateError('Access token is empty'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: 401,
            statusMessage: 'Unauthorized',
          ),
        ));
        return;
      }
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
    final token = MySafarSdk.tokens.accessToken ?? '';

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
    options.extra['dioClient'] = DioClient.skote;
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
