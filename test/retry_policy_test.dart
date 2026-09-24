import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/config/dio_client.dart';

DioException _error(
  String method, {
  int? status,
  DioExceptionType type = DioExceptionType.badResponse,
  bool retryable = false,
}) {
  final options = RequestOptions(
    path: '/x',
    method: method,
    extra: {if (retryable) 'retryable': true},
  );
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status),
  );
}

void main() {
  group('shouldRetryRequest', () {
    test('bron/to\'lov POST 502/503/504 da qayta yuborilmaydi', () {
      for (final code in [502, 503, 504]) {
        expect(shouldRetryRequest(_error('POST', status: code)), isFalse,
            reason: 'POST $code');
      }
      expect(
        shouldRetryRequest(
            _error('POST', type: DioExceptionType.connectionError)),
        isFalse,
      );
    });

    test('POST ulanib bo\'lmaganda (so\'rov yetmagan) qayta yuboriladi', () {
      expect(
        shouldRetryRequest(
            _error('POST', type: DioExceptionType.connectionTimeout)),
        isTrue,
      );
    });

    test('retryable POST (qidiruv) va GET 502/504 da qayta yuboriladi', () {
      expect(shouldRetryRequest(_error('POST', status: 502, retryable: true)),
          isTrue);
      expect(shouldRetryRequest(_error('GET', status: 504)), isTrue);
      expect(
        shouldRetryRequest(
            _error('GET', type: DioExceptionType.connectionError)),
        isTrue,
      );
    });

    test('4xx va bekor qilingan so\'rov qayta yuborilmaydi', () {
      expect(shouldRetryRequest(_error('GET', status: 400)), isFalse);
      expect(
        shouldRetryRequest(_error('GET', type: DioExceptionType.cancel)),
        isFalse,
      );
    });
  });
}
