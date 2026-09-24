import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => SdkLocalization.localeNotifier.value = const Locale('uz'));

  test('host tili (save: false) API tiliga ham o\'tadi', () {
    // MySafarEmbed(locale: ru) — storage'ga yozilmaydi, faqat faol til.
    SdkLocalization.localeNotifier.value = const Locale('ru');
    expect(currentLang(), 'ru');
    expect(dataLang(), 'ru');
  });

  test('kk/tg → ru, tr → en (backend faqat uz/ru/en)', () {
    SdkLocalization.localeNotifier.value = const Locale('kk');
    expect(currentLang(), 'kk');
    expect(dataLang(), 'ru');
    SdkLocalization.localeNotifier.value = const Locale('tr');
    expect(dataLang(), 'en');
  });
}
