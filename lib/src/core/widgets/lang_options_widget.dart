import 'package:mysafar_sdk/src/core/config/sdk_storage.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart'
    show SdkSheetFrame;
import 'package:mysafar_sdk/src/core/widgets/sdk_option_sheet.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

/// Til tanlash sheet'i — yangi UI'dagi tanlov ro'yxati (bayroq, nom,
/// tanlov belgisi).
class LangOptionsWidget extends StatelessWidget {
  const LangOptionsWidget({super.key});

  static const List<(String code, String title)> _languages = [
    ("uz", "O'zbekcha"),
    ("ru", "Русский"),
    ("en", "English"),
    ("kk", "Қазақша"),
    ("tg", "Тоҷикӣ"),
    ("tr", "Türkçe"),
  ];

  @override
  Widget build(BuildContext context) {
    return SdkSheetFrame(
      child: SdkOptionList<String>(
        title: "lang".tr(),
        selected: context.locale.languageCode,
        options: [
          for (final (code, title) in _languages)
            SdkOptionItem(
              value: code,
              title: title,
              leading: SdkRoundFlag(image: _flag(code)),
            ),
        ],
        onSelected: (code) {
          sdkStorage().write("lang", code);
          context.setLocale(Locale(code));
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _flag(String code) {
    final path = switch (code) {
      "uz" => Assets.splashUzFlag,
      "ru" => Assets.splashRuFlag,
      "en" => Assets.splashEnFlag,
      "kk" => Assets.flagsKz,
      "tg" => Assets.flagsTj,
      "tr" => Assets.flagsTr,
      _ => "",
    };
    if (path.isEmpty) return const SizedBox.shrink();
    return path.endsWith(".svg")
        ? SvgPicture.asset(path, fit: BoxFit.cover)
        : Image.asset(path, fit: BoxFit.cover);
  }
}
