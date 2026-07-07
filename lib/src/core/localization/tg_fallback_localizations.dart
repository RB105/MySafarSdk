import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter'ning built-in Material/Cupertino/Widgets localization'lari `tg`
/// (tojik) tilini qo'llab-quvvatlamaydi. Bu delegatelar faqat `tg` uchun
/// ishlab, ichida rus tilidagi (`ru`) localization'larni yuklaydi. Shu tarzda
/// tojik tilida MaterialLocalizations topilmadi degan xato chiqmaydi.
const Locale _tgFallbackLocale = Locale('ru');

class _MaterialLocalizationsTgDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsTgDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_tgFallbackLocale);

  @override
  bool shouldReload(_MaterialLocalizationsTgDelegate old) => false;
}

class _CupertinoLocalizationsTgDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoLocalizationsTgDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_tgFallbackLocale);

  @override
  bool shouldReload(_CupertinoLocalizationsTgDelegate old) => false;
}

class _WidgetsLocalizationsTgDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _WidgetsLocalizationsTgDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tg';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_tgFallbackLocale);

  @override
  bool shouldReload(_WidgetsLocalizationsTgDelegate old) => false;
}

/// `context.localizationDelegates` ro'yxatidan oldin qo'shiladi. Delegate
/// resolution ro'yxatdagi birinchi mos delegate'ni tanlaydi, shuning uchun
/// bular birinchi bo'lib turishi kerak — `tg` uchun ishlaydi, boshqa tillar
/// uchun `isSupported` false qaytarib, Global delegatelarga o'tadi.
const List<LocalizationsDelegate<dynamic>> tgFallbackDelegates = [
  _MaterialLocalizationsTgDelegate(),
  _CupertinoLocalizationsTgDelegate(),
  _WidgetsLocalizationsTgDelegate(),
];