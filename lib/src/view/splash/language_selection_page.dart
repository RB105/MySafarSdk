import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/grarient_box_border.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/service/analytics/analytics_service.dart';
import 'package:mysafar_sdk/src/view/splash/onboarding_screen.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  static const String routeName = "/splashLang";

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage>
    with TickerProviderStateMixin {
  String selectedLang = "uz";

  static const List<({String code, String title})> _languages = [
    (code: "uz", title: "O'zbek tili"),
    (code: "ru", title: "Русский язык"),
    (code: "en", title: "English"),
    (code: "kk", title: "Қазақ тілі"),
    (code: "tg", title: "Забони тоҷикӣ"),
    (code: "tr", title: "Türkçe"),
  ];

  late final AnimationController _topController;
  late final AnimationController _bottomController;

  late final Animation<Offset> _topOffset;
  late final Animation<Offset> _bottomOffset;

  @override
  void initState() {
    super.initState();

    _topController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _bottomController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _topOffset =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _topController, curve: Curves.easeOut),
    );
    _bottomOffset =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _bottomController, curve: Curves.easeOut),
    );

    _topController.forward();
    _bottomController.forward();
  }

  @override
  void dispose() {
    _topController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        bottom: Platform.isAndroid,
        top: Platform.isAndroid,
        child: Scaffold(
          body: Padding(
            padding: context.k16horizontalPadding,
            child: Column(
              children: [
                SlideTransition(
                  position: _topOffset,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: SizedBox(
                          height: 64,
                          child: SvgPicture.asset(Assets.homeLogoFull),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "choose_lang".tr(),
                          style: context.textTheme.displayLarge,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "choose_lang_desc".tr(),
                          style: context.textTheme.titleSmall
                              ?.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                SlideTransition(
                  position: _bottomOffset,
                  child: Column(
                    children: [
                      for (final l in _languages) ...[
                        InkWell(
                          onTap: () => setState(() {
                            selectedLang = l.code;
                            context.setLocale(Locale(selectedLang));
                          }),
                          child: _LangSelectionWidget(
                            selected: selectedLang == l.code,
                            title: l.title,
                            code: l.code,
                          ),
                        ),
                        context.szBoxHeight12,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: SlideTransition(
            position: _bottomOffset,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    AnalyticsService().trackButtonTap('language_continue',
                        extra: {'lang': selectedLang});
                    GetStorage().write("lang", selectedLang);
                    context.setLocale(Locale(selectedLang));
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        OnBoardingScreen.routeName, (route) => false);
                  },
                  style: ProjectTheme.blueButtonStyle,
                  child: Text("next".tr()),
                ),
              ),
            ),
          ),
        ));
  }
}

class _LangSelectionWidget extends StatelessWidget {
  const _LangSelectionWidget({
    required this.selected,
    required this.title,
    required this.code,
  });

  final bool selected;
  final String title;
  final String code;

  static String _flagAsset(String code) {
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

  @override
  Widget build(BuildContext context) {
    final flagPath = _flagAsset(code);
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.color.primaryContainer,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: selected ? null : context.shadowDown,
          border: selected
              ? GradientBoxBorder(
                  gradient: LinearGradient(colors: ProjectTheme.focusGradient),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: flagPath.endsWith(".svg")
                      ? SvgPicture.asset(flagPath, fit: BoxFit.cover)
                      : Image.asset(flagPath, fit: BoxFit.cover),
                ),
              ),
              context.szBoxWidth12,
              Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(),
              ),
              const Spacer(),
              if (selected)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(Assets.ticketsDoneIcon),
                )
            ],
          ),
        ),
      ),
    );
  }
}
