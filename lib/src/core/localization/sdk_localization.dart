import 'dart:convert' show json;
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';

// SDK ichida DateFormat/NumberFormat ilgari easy_localization re-export'idan
// kelardi — endi to'g'ridan-to'g'ri intl'dan (TextDirection to'qnashuvi
// yashiriladi, avvalgidek).
export 'package:intl/intl.dart' hide TextDirection;

/// SDK'ning IZOLYATSIYALANGAN lokalizatsiyasi.
///
/// Ilgari easy_localization ishlatilardi — u esa GLOBAL singleton'ga
/// (`Localization.instance`) tayanadi: host app (masalan Unired) ham
/// easy_localization ishlatsa, SDK ochilganda tarjimalar almashib, host
/// ekranlaridagi matnlar buzilardi. Bu klass faqat SDK'ning o'z JSON'larini
/// (`packages/mysafar_sdk/assets/lang/`) o'qiydi va hech qanday global holatga
/// tegmaydi — host'ning lokalizatsiyasiga mutlaqo ta'sir qilmaydi.
class SdkLocalization {
  SdkLocalization._();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
    Locale('kk'),
    Locale('tg'),
    Locale('tr'),
  ];

  static const String _fallbackCode = 'uz';
  static const String _langKey = 'lang';

  /// Joriy til — o'zgarganda SDK'ning MaterialApp'i qayta quriladi.
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale(_fallbackCode));

  static Locale get locale => localeNotifier.value;

  static Map<String, dynamic> _strings = const {};
  static Map<String, dynamic> _fallbackStrings = const {};
  static bool _persist = true;

  /// `MySafarSdk.init` chaqiradi. [startLocale] berilmasa SDK'ning o'z
  /// storage'idagi oxirgi tanlov, u ham bo'lmasa `uz`.
  static Future<void> init({Locale? startLocale, bool persist = true}) async {
    _persist = persist;
    _fallbackStrings = await _loadJson(_fallbackCode);
    final code = startLocale?.languageCode ??
        sdkStorage().read<String>(_langKey) ??
        _fallbackCode;
    await setLocale(Locale(code), save: false);
  }

  static Future<void> setLocale(Locale newLocale, {bool save = true}) async {
    final code = supportedLocales
            .any((l) => l.languageCode == newLocale.languageCode)
        ? newLocale.languageCode
        : _fallbackCode;
    _strings = code == _fallbackCode ? _fallbackStrings : await _loadJson(code);
    localeNotifier.value = Locale(code);
    if (save && _persist) await sdkStorage().write(_langKey, code);
  }

  static Future<Map<String, dynamic>> _loadJson(String code) async {
    try {
      final raw = await rootBundle
          .loadString('packages/mysafar_sdk/assets/lang/$code.json');
      return json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('SdkLocalization: $code.json yuklanmadi: $e');
      return const {};
    }
  }

  /// easy_localization bilan bir xil format: pozitsion `{}` va nomlangan
  /// `{name}` placeholderlar.
  static String translate(String key,
      {List<String>? args, Map<String, String>? namedArgs}) {
    var value =
        (_strings[key] ?? _fallbackStrings[key])?.toString() ?? key;
    if (namedArgs != null) {
      namedArgs.forEach((k, v) => value = value.replaceAll('{$k}', v));
    }
    if (args != null) {
      for (final a in args) {
        value = value.replaceFirst('{}', a);
      }
    }
    return value;
  }
}

/// easy_localization'ning `'key'.tr()` sintaksisi bilan drop-in mos.
extension SdkStringTr on String {
  String tr({List<String>? args, Map<String, String>? namedArgs}) =>
      SdkLocalization.translate(this, args: args, namedArgs: namedArgs);
}

/// easy_localization'ning `context.locale` / `context.setLocale` o'rnini
/// bosadi — kod o'zgarmasdan ishlayveradi.
extension SdkLocaleContext on BuildContext {
  Locale get locale => SdkLocalization.locale;

  Future<void> setLocale(Locale value) => SdkLocalization.setLocale(value);
}
