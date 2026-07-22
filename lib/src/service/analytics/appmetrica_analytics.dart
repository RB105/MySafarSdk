import 'dart:async' show unawaited;

import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mysafar_sdk/src/api/analytics.dart';

/// `MySafarAnalytics` uchun AppMetrica implementatsiyasi.
/// `MySafarSdk.init` ichida `appMetricaApiKey` berilganda avtomatik ulanadi.
class AppMetricaAnalytics extends MySafarAnalytics {
  const AppMetricaAnalytics();

  @override
  Future<void> logEvent(String name, [Map<String, Object>? attributes]) async {
    try {
      if (attributes == null || attributes.isEmpty) {
        await AppMetrica.reportEvent(name);
      } else {
        await AppMetrica.reportEventWithMap(name, attributes);
      }
    } catch (e) {
      debugPrint('AppMetricaAnalytics.logEvent failed ($name): $e');
    }
  }

  @override
  Future<void> setEnvironmentValue(String key, String value) async {
    try {
      await AppMetrica.putAppEnvironmentValue(key, value);
    } catch (e) {
      debugPrint('AppMetricaAnalytics.setEnvironmentValue failed ($key): $e');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await AppMetrica.setUserProfileID(userId);
    } catch (e) {
      debugPrint('AppMetricaAnalytics.setUserId failed: $e');
    }
  }

  @override
  Future<void> setUserAttributes(Map<String, Object> attributes) async {
    if (attributes.isEmpty) return;
    try {
      final profileAttributes = [
        for (final entry in attributes.entries)
          AppMetricaStringAttribute.withValue(
            entry.key,
            entry.value.toString(),
          ),
      ];
      await AppMetrica.reportUserProfile(
        AppMetricaUserProfile(profileAttributes),
      );
    } catch (e) {
      debugPrint('AppMetricaAnalytics.setUserAttributes failed: $e');
    }
  }

  @override
  Future<void> trackRevenue({
    required num amount,
    required String currency,
    int quantity = 1,
    String? productId,
  }) async {
    try {
      await AppMetrica.reportRevenue(
        AppMetricaRevenue(
          Decimal.parse(amount.toString()),
          currency,
          quantity: quantity,
          productId: productId,
        ),
      );
    } catch (e) {
      debugPrint('AppMetricaAnalytics.trackRevenue failed: $e');
    }
  }

  @override
  void reportAppOpen(String link) {
    unawaited(() async {
      try {
        await AppMetrica.reportAppOpen(link);
      } catch (e) {
        debugPrint('AppMetricaAnalytics.reportAppOpen failed: $e');
      }
    }());
  }
}
