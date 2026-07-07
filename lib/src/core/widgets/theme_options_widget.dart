import 'dart:io';

import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart' show ThemeNotifier;
import 'package:mysafar_sdk/src/generated/assets.dart' show Assets;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:provider/provider.dart' show Provider;

class ThemeOptionsWidget extends StatefulWidget {
  const ThemeOptionsWidget({super.key});

  @override
  State<ThemeOptionsWidget> createState() => _ThemeOptionsWidgetState();
}

class _ThemeOptionsWidgetState extends State<ThemeOptionsWidget> {
  late ThemeMode current;
  late ThemeNotifier themeNotifier;

  @override
  void didChangeDependencies() {
    themeNotifier = Provider.of<ThemeNotifier>(context);
    current = themeNotifier.themeMode;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        bottom: Platform.isAndroid,
        top: Platform.isAndroid,

        child:DecoratedBox(
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
                  Text("theme".tr(), style: context.textTheme.bodyMedium),
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

            /// Options

            Padding(
              padding: context.k16horizontalPadding,
              child: Column(
                children: [
                  _buildOption("system".tr(), ThemeMode.system),
                  context.szBoxHeight16,
                  _buildOption("dark".tr(), ThemeMode.dark),
                  context.szBoxHeight16,
                  _buildOption("light".tr(), ThemeMode.light),
                  context.szBoxHeight16,
                ],
              ),
            ),

            context.szBoxHeight16
          ]),
        )));
  }

  Widget _buildOption(String title, ThemeMode mode) {
    return InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: () {
          // Tanlash qilingan bilan darhol qo'llash
          themeNotifier.setTheme(mode);
          Navigator.pop(context);
        },
        child: Row(children: [
          SizedBox(
            width: 24,
            height: 24,
            child: SvgPicture.asset(_getIcon(mode), colorFilter: ColorFilter.mode(context.themeProvider.isDark?Colors.white:Colors.black, BlendMode.srcIn),),
          ),
          context.szBoxWidth8,
          Text(title),
          Spacer(),
          Visibility(
              visible: current == mode,
              replacement: SizedBox.shrink(),
              child: Icon(Icons.check_circle,
                  color:ProjectTheme.success))
        ]));
  }

  String _getIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Assets.profileSystemColorIcon;
      case ThemeMode.dark:
        return Assets.profileDarkModeIcon;
      case ThemeMode.light:
        return Assets.profileLightModeIcon;
    }
  }
}
