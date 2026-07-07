import 'package:get_storage/get_storage.dart';

/// Language code currently selected for the app UI (matches the active locale).
String currentLang() => GetStorage().read('lang') ?? 'uz';

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
