import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/api/config.dart';
import 'package:mysafar_sdk/src/core/config/app_config.dart';

void main() {
  group('AppConfig.apply', () {
    test('config qiymatlarini static fieldlarga o\'tkazadi (trim bilan)', () {
      AppConfig.apply(const MySafarConfig(
        baseUrl: ' https://api.example.com ',
        skoteBaseUrl: 'https://cms.example.com/api',
        partnerToken: ' token-123 ',
      ));

      expect(AppConfig.baseUrl, 'https://api.example.com');
      expect(AppConfig.skoteBaseUrl, 'https://cms.example.com/api');
      expect(AppConfig.partnerToken, 'token-123');
      expect(AppConfig.isLoaded, isTrue);
      expect(AppConfig.hasValidPartnerToken, isTrue);
    });

    test('yechilmagan build placeholder token invalid hisoblanadi', () {
      AppConfig.apply(const MySafarConfig(
        baseUrl: 'https://api.example.com',
        skoteBaseUrl: 'https://cms.example.com/api',
        partnerToken: r'$(PARTNER_TOKEN)',
      ));

      expect(AppConfig.hasValidPartnerToken, isFalse);
    });

    test('bo\'sh partner token invalid', () {
      AppConfig.apply(const MySafarConfig(
        baseUrl: 'https://api.example.com',
        skoteBaseUrl: 'https://cms.example.com/api',
      ));

      expect(AppConfig.hasValidPartnerToken, isFalse);
    });
  });

  group('MySafarConfig.support', () {
    test('berilmasa default telefon va telegram', () {
      const config = MySafarConfig(
        baseUrl: 'https://api.example.com',
        skoteBaseUrl: 'https://cms.example.com/api',
      );

      expect(config.supportPhone, MySafarSupportConfig.defaultPhone);
      expect(
          config.supportTelegramUrl, MySafarSupportConfig.defaultTelegramUrl);
    });

    test('host telefon va telegram berilsa shular ishlatiladi', () {
      const config = MySafarConfig(
        baseUrl: 'https://api.example.com',
        skoteBaseUrl: 'https://cms.example.com/api',
        support: MySafarSupportConfig(
          phone: '+998 90 111 22 33',
          telegramUrl: 'https://t.me/partner_bot',
        ),
      );

      expect(config.supportPhone, '+998 90 111 22 33');
      expect(config.supportTelegramUrl, 'https://t.me/partner_bot');
    });

    test('telegram @handle to\'liq URL ga aylanadi', () {
      const config = MySafarConfig(
        baseUrl: 'https://api.example.com',
        skoteBaseUrl: 'https://cms.example.com/api',
        support: MySafarSupportConfig(telegramUrl: '@partner_bot'),
      );

      expect(config.supportTelegramUrl, 'https://t.me/partner_bot');
    });
  });
}
