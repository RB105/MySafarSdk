// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart' show ThemeNotifier;
import 'package:mysafar_sdk/src/core/tools/currency_provider.dart';
import 'package:provider/provider.dart' show ReadContext;

extension SizeContext on BuildContext {
  ThemeNotifier get themeProvider => read<ThemeNotifier>();
  CurrencyProvider get currencyProvider => read<CurrencyProvider>();
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;

  EdgeInsets get k6horizontalPadding => EdgeInsets.symmetric(horizontal: 6);
  EdgeInsets get k8horizontalPadding => EdgeInsets.symmetric(horizontal: 8);
  EdgeInsets get k10horizontalPadding => EdgeInsets.symmetric(horizontal: 10);
  EdgeInsets get k12horizontalPadding => EdgeInsets.symmetric(horizontal: 12);
  EdgeInsets get k14horizontalPadding => EdgeInsets.symmetric(horizontal: 14);
  EdgeInsets get k16horizontalPadding => EdgeInsets.symmetric(horizontal: 16);
  EdgeInsets get k20horizontalPadding => EdgeInsets.symmetric(horizontal: 20);
  EdgeInsets get k32horizontalPadding => EdgeInsets.symmetric(horizontal: 32);
  EdgeInsets get k16Padding => EdgeInsets.all(16);
  EdgeInsets get k12Padding => EdgeInsets.all(12);
  EdgeInsets get k8Padding => EdgeInsets.all(8);
  EdgeInsets get k4Padding => EdgeInsets.all(4);

  EdgeInsets get k6verticalPadding => EdgeInsets.symmetric(vertical: 6);
  EdgeInsets get k8verticalPadding => EdgeInsets.symmetric(vertical: 8);
  EdgeInsets get k12verticalPadding => EdgeInsets.symmetric(vertical: 12);
  EdgeInsets get k14verticalPadding => EdgeInsets.symmetric(vertical: 14);
  EdgeInsets get k16verticalPadding => EdgeInsets.symmetric(vertical: 16);
  EdgeInsets get k20verticalPadding => EdgeInsets.symmetric(vertical: 20);

  SizedBox get szBoxHeight32 => SizedBox(height: 32);
  SizedBox get szBoxHeight24 => SizedBox(height: 24);
  SizedBox get szBoxHeight16 => SizedBox(height: 16);
  SizedBox get szBoxHeight12 => SizedBox(height: 12);
  SizedBox get szBoxHeight8 => SizedBox(height: 8);
  SizedBox get szBoxHeight4 => SizedBox(height: 4);
  SizedBox get szNavbarHeight => SizedBox(height: bottomPadding);

  SizedBox get szBoxWidth2 => SizedBox(width: 2.0);
  SizedBox get szBoxWidth4 => SizedBox(width: 4.0);
  SizedBox get szBoxWidth8 => SizedBox(width: 8.0);
  SizedBox get szBoxWidth12 => SizedBox(width: 12.0);
  SizedBox get szBoxWidth16 => SizedBox(width: 16.0);
  SizedBox get szBoxWidth24 => SizedBox(width: 24);

  double get radius4 => 4;
  double get radius8 => 8;
  double get radius12 => 12;

  double get k8Space => 8;

  double get k12Space => 12;

  double get k16Space => 16;

  double get k24Space => 24;

  double get bottomPadding => MediaQuery.of(this).padding.bottom;

  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get color => Theme.of(this).colorScheme;

  List<BoxShadow> get shadowDown => [
        BoxShadow(
          color: themeProvider.isDark
              ? Colors.black.withOpacity(0.5)
              : Color(0xffC6C7C9).withOpacity(0.5),
          blurRadius: 8.0,
          offset: const Offset(0, 2),
        ),
      ];

  List<BoxShadow> get shadowUp => [
        BoxShadow(
            color: themeProvider.isDark
                ? Colors.black.withOpacity(0.5)
                : Color(0xffC6C7C9).withOpacity(0.5),
            blurRadius: 8.0,
            offset: Offset(0, -2))
      ];

  Border get boxBorder => Border.all(
      width: 1,
      color: themeProvider.isDark ? ProjectTheme.borderDark : ProjectTheme.borderLight);

  Border get boxErrorBorder => Border.all(width: 1, color: ProjectTheme.error);

  Color get inputColor =>
      themeProvider.isDark ? ProjectTheme.inputColorDark : ProjectTheme.inputColorLight;

  Color get disabledBgColor => themeProvider.isDark
      ? ProjectTheme.disabledBackgroundDark
      : ProjectTheme.disabledBackgroundLight;
  
  Color get backgroundColor => themeProvider.isDark
      ? ProjectTheme.backgroundDark
      : ProjectTheme.backgroundLight;

  Color get disabledTextColor => themeProvider.isDark
      ? ProjectTheme.disabledTextDark
      : ProjectTheme.disabledTextLight;

  ButtonStyle get disabledButtonStyle => themeProvider.isDark
      ? ProjectTheme.disabledButtonDarkStyle
      : ProjectTheme.disabledButtonLightStyle;

  Color get lightDrop2 =>
      themeProvider.isDark ? ProjectTheme.lightDrop2Dark : ProjectTheme.lightDrop2Light;

  ButtonStyle get filterCancelButtonStyle {
    final isDark = themeProvider.isDark;
    return ElevatedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : ProjectTheme.brandColor,
        backgroundColor: color.primaryContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isDark
                ? BorderSide(width: 1, color: Colors.white)
                : BorderSide(width: 1, color: ProjectTheme.brandColor)));
  }
}
