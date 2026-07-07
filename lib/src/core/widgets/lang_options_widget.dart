import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class LangOptionsWidget extends StatefulWidget {
  const LangOptionsWidget({super.key});

  @override
  State<LangOptionsWidget> createState() => _LangOptionsWidgetState();
}

class _LangOptionsWidgetState extends State<LangOptionsWidget> {
  late String lang;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    lang = context.locale.languageCode;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        bottom: Platform.isAndroid,
        top: Platform.isAndroid,

        child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Padding(
            padding: context.k16verticalPadding,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              /// Header Row
              Padding(
                padding: context.k16horizontalPadding,
                child: Row(
                  children: [
                    Text("lang".tr(), style: context.textTheme.bodyMedium),
                    Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Divider(thickness: 1, color: context.color.outline),
              context.szBoxHeight12,

              /// Language Options

              Padding(
                padding: context.k16horizontalPadding,
                child: Column(
                  children: [
                    _buildOption("O'zbekcha", "uz"),
                    context.szBoxHeight16,
                    _buildOption("Русский", "ru"),
                    context.szBoxHeight16,
                    _buildOption("English", "en"),
                    context.szBoxHeight16,
                    _buildOption("Қазақша", "kk"),
                    context.szBoxHeight16,
                    _buildOption("Тоҷикӣ", "tg"),
                    context.szBoxHeight16,
                    _buildOption("Türkçe", "tr"),
                    context.szBoxHeight16,
                  ],
                ),
              ),
              context.szBoxHeight16
            ]))));
  }

  Widget _buildOption(String title, String code) {
    return InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: () {
          GetStorage().write("lang", code);
          context.setLocale(Locale(code));
          Navigator.pop(context);
        },
        child: Row(children: [
          buildFlag(code, 24),
          context.szBoxWidth12,
          Text(title),
          Spacer(),
          Visibility(
              visible: lang == code,
              replacement: SizedBox.shrink(),
              child: Icon(Icons.check_circle,
                  color:ProjectTheme.success))
        ]));
  }

  String getFlag(String code) {
    switch (code) {
      case "uz":
        return Assets.splashUzFlag;
      case "ru":
        return Assets.splashRuFlag;
      case "en":
        return Assets.splashEnFlag;
      case "kk":
        return Assets.flagsKz;
      case "tg":
        return Assets.flagsTj;
      case "tr":
        return Assets.flagsTr;
      default:
        return "";
    }
  }

  Widget buildFlag(String code, double size) {
    final path = getFlag(code);
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: path.endsWith(".svg")
            ? SvgPicture.asset(path, fit: BoxFit.cover)
            : Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }
}
