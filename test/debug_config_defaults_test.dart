import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/api/config.dart';
import 'package:mysafar_sdk/src/core/config/debug_config_defaults.dart';

void main() {
  const env = {
    DebugConfigDefaults.baseUrlKey: 'https://api.example.com',
    DebugConfigDefaults.skoteBaseUrlKey: 'https://cms.example.com/api',
    DebugConfigDefaults.partnerTokenKey: 'debug-token',
    DebugConfigDefaults.appNameKey: 'Unired',
  };

  const emptyConfig = MySafarConfig(baseUrl: '', skoteBaseUrl: '');

  group('DebugConfigDefaults.apply — debug', () {
    test('bo\'sh maydonlar env qiymatlari bilan to\'ldiriladi', () {
      final result =
          DebugConfigDefaults.apply(emptyConfig, isDebug: true, env: env);

      expect(result.baseUrl, 'https://api.example.com');
      expect(result.skoteBaseUrl, 'https://cms.example.com/api');
      expect(result.partnerToken, 'debug-token');
      expect(result.appName, 'Unired');
    });

    test('host bergan qiymatlar ustun — env ularni almashtirmaydi', () {
      const host = MySafarConfig(
        baseUrl: 'https://host.api',
        skoteBaseUrl: 'https://host.cms',
        partnerToken: 'host-token',
        appName: 'Host',
      );

      final result = DebugConfigDefaults.apply(host, isDebug: true, env: env);

      expect(result.baseUrl, 'https://host.api');
      expect(result.skoteBaseUrl, 'https://host.cms');
      expect(result.partnerToken, 'host-token');
      expect(result.appName, 'Host');
    });

    test('faqat bo\'sh maydon to\'ldiriladi, qolgan sozlamalar saqlanadi', () {
      const host = MySafarConfig(
        baseUrl: 'https://host.api',
        skoteBaseUrl: '  ',
        enableMultiSearch: false,
        brandColor: Colors.green,
      );

      final result = DebugConfigDefaults.apply(host, isDebug: true, env: env);

      expect(result.baseUrl, 'https://host.api');
      expect(result.skoteBaseUrl, 'https://cms.example.com/api');
      expect(result.partnerToken, 'debug-token');
      expect(result.enableMultiSearch, isFalse);
      expect(result.brandColor, Colors.green);
    });

    test('env bo\'sh bo\'lsa config o\'zgarmaydi', () {
      final result =
          DebugConfigDefaults.apply(emptyConfig, isDebug: true, env: const {});

      expect(identical(result, emptyConfig), isTrue);
    });
  });

  group('DebugConfigDefaults.apply — release', () {
    test('env berilgan bo\'lsa ham hech narsa to\'ldirilmaydi', () {
      final result =
          DebugConfigDefaults.apply(emptyConfig, isDebug: false, env: env);

      expect(identical(result, emptyConfig), isTrue);
      expect(result.partnerToken, isEmpty);
      expect(result.appName, isNull);
    });
  });
}
