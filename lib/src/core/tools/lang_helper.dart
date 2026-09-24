import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';

/// Language code currently selected for the app UI (matches the active locale).
///
/// SDK'ning faol tilidan o'qiladi, storage'dan emas: embed rejimda host tili
/// (`MySafarEmbed(locale:)`) storage'ga yozilmaydi (`save: false`), shuning
/// uchun storage eski yoki standart `uz` bo'lib qolardi va rus tilidagi
/// foydalanuvchiga server xabarlari, davlat nomlari o'zbekcha chiqardi.
String currentLang() => SdkLocalization.locale.languageCode;

/// Maps the selected UI language to a language code that the app's static and
/// back-end data actually ship. Localized data (country names, destination
/// names, class names, etc.) only provides `uz`, `ru` and `en`, so newly added
/// locales fall back to the closest available data language:
///   * `kk` (Kazakh) and `tg` (Tajik) -> `ru`
///   * `tr` (Turkish)                  -> `en`
/// The result is always one of `uz` / `ru` / `en`, so indexing localized data
/// with it never returns null.
String dataLang([String? code]) {
  switch (code ?? currentLang()) {
    case 'kk':
    case 'tg':
      return 'ru';
    case 'tr':
      return 'en';
    case 'ru':
      return 'ru';
    case 'en':
      return 'en';
    default:
      return 'uz';
  }
}
