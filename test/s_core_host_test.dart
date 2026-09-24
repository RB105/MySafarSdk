import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/config/dio_client.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/service/cache/hive_service.dart';

DioException _err({int? status, DioExceptionType? type}) {
  final options = RequestOptions(path: '/api/v1/token/refresh/');
  return DioException(
    requestOptions: options,
    type: type ?? DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status),
  );
}

String _jwt(Map<String, Object?> payload) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(payload)}.sig';
}

void main() {
  group('classifyRefreshFailure (№76)', () {
    test('server rad etdi — invalid', () {
      for (final code in [400, 401, 403]) {
        expect(classifyRefreshFailure(_err(status: code)),
            RefreshOutcome.invalid);
      }
    });

    test('tarmoq / 5xx — tokenlar qoladi', () {
      expect(
          classifyRefreshFailure(
              _err(type: DioExceptionType.connectionError)),
          RefreshOutcome.networkError);
      expect(
          classifyRefreshFailure(
              _err(type: DioExceptionType.receiveTimeout)),
          RefreshOutcome.networkError);
      expect(classifyRefreshFailure(_err(status: 502)),
          RefreshOutcome.networkError);
      expect(classifyRefreshFailure(_err(status: 500)),
          RefreshOutcome.networkError);
    });
  });

  group('analytics profil ID (№97)', () {
    test('telefon raqami profil ID emas', () {
      expect(AnalyticsService.looksLikePhone('998901234567'), isTrue);
      expect(AnalyticsService.looksLikePhone('+998901234567'), isTrue);
      expect(AnalyticsService.looksLikePhone('12345'), isFalse);
      expect(AnalyticsService.looksLikePhone('abc'), isFalse);
    });

    test('JWT user_id o\'qiladi', () {
      expect(AnalyticsService.userIdFromJwt(_jwt({'user_id': 42})), '42');
      expect(AnalyticsService.userIdFromJwt(_jwt({'exp': 1})), isNull);
      expect(AnalyticsService.userIdFromJwt('not-a-jwt'), isNull);
      expect(AnalyticsService.userIdFromJwt(null), isNull);
    });

    test('webRegister: yangi hisob belgisi', () {
      expect(AnalyticsService.isNewUserResponse({'created': true}), isTrue);
      expect(AnalyticsService.isNewUserResponse({'is_new': true}), isTrue);
      expect(AnalyticsService.isNewUserResponse({'jwt_token': {}}), isFalse);
      expect(AnalyticsService.isNewUserResponse(null), isFalse);
    });
  });

  test('Hive box nomlari prefiksli (№94)', () {
    expect(HiveService.physicalName('profile_cache'), 'mysafar_profile_cache');
    expect(HiveService.physicalName('mysafar_x'), 'mysafar_x');
  });
}
