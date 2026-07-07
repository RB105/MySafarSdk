import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';

class SwitchButtonWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchButtonWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoSwitch(
            value: value,
            activeTrackColor: ProjectTheme.brandColor,
            onChanged: onChanged)
        : Switch.adaptive(
            value: value,
            activeTrackColor: ProjectTheme.brandColor,
            inactiveThumbColor: ProjectTheme.disabledBackgroundDark,
            trackOutlineColor:
                WidgetStatePropertyAll(ProjectTheme.disabledBackgroundLight),
            onChanged: onChanged,
          );
  }
}
