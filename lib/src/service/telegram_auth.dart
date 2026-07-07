import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mysafar_sdk/src/api/sdk.dart' show MySafarSdk;
import 'package:telegram_login/telegram_login.dart';

class TelegramLoginService {
  static Future<String?> loginWithTelegram() async {
    // Client ID / redirect'lar endi hardcode emas — host `MySafarConfig
    // .socialAuth.telegram` orqali beradi. Berilmagan bo'lsa login o'tkazilmaydi
    // (tugma ham UI'da ko'rsatilmaydi, bu himoya chegarasi xolos).
    final config = MySafarSdk.config.socialAuth?.telegram;
    if (config == null) {
      debugPrint('TelegramLoginService: telegram auth is not configured');
      return null;
    }

    final telegramLogin = TelegramLogin();

    await telegramLogin.configure(
      TelegramLoginConfiguration(
        clientId: config.clientId,
        redirectUri: Platform.isAndroid
            ? (kDebugMode
                ? (config.redirectUriAndroidDebug ?? config.redirectUriAndroid)
                : config.redirectUriAndroid)
            : config.redirectUriIos,
        scopes: const ['profile', "phone"],
      ),
    );
    final result = await telegramLogin.login();
    if (kDebugMode) {
      debugPrint('Telegram ID token received: ${result.idToken.isNotEmpty}');
    }
    return result.idToken;
  }
}
