import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:telegram_login/telegram_login.dart';

class TelegramLoginService {
  static Future<String?> loginWithTelegram() async {
    final telegramLogin = TelegramLogin();

    await telegramLogin.configure(
      TelegramLoginConfiguration(
        clientId: '8564524682',
        redirectUri: Platform.isAndroid
            ? (kDebugMode
                    ? 'https://app337613136-login.tg.dev' // Debug
                    : 'https://app1749756658-login.tg.dev' // GOOGLE PLAY SHA-256
                )
            : "https://app1896443054-login.tg.dev",
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
