import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart';

/// Embed'da root navigator host'niki — SDK theme/provider yo'qoladi.
/// Shu helperlar doim SDK ichki navigator'da ochadi.
///
/// Tema **jonli**: `ThemeNotifier` o'zgaganda ochiq sheet ham yangilanadi.
/// Rang manbai — MaterialApp'da chizilayotgan `Theme.of(parent)` brightness
/// (`ThemeNotifier.isDark` bilan sinxrondan chiqmaslik uchun).

ThemeNotifier? _tryThemeNotifier(BuildContext context) {
  try {
    return context.themeProvider;
  } catch (_) {
    return null;
  }
}

/// Sahifada ko'rinayotgan tema — sheet ham shunga moslashadi.
ThemeData _pageTheme(BuildContext parentContext) {
  final isDark = Theme.of(parentContext).brightness == Brightness.dark;
  return isDark ? ProjectTheme.dark : ProjectTheme.light;
}

Color? _liveSheetFill({
  required Color? backgroundColor,
  required BuildContext parentContext,
}) {
  if (backgroundColor == Colors.transparent) return null;

  final isDark = Theme.of(parentContext).brightness == Brightness.dark;
  return isDark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight;
}

Widget _wrapLiveTheme({
  required BuildContext parentContext,
  required ThemeNotifier? notifier,
  required Color? backgroundColor,
  required ShapeBorder? shape,
  required Clip? clipBehavior,
  required WidgetBuilder builder,
}) {
  Widget buildFor() {
    final theme = _pageTheme(parentContext);
    final fill = _liveSheetFill(
      backgroundColor: backgroundColor,
      parentContext: parentContext,
    );
    Widget result = Theme(
      data: theme,
      child: Builder(builder: builder),
    );
    if (fill != null) {
      result = Material(
        color: fill,
        shape: shape,
        clipBehavior: clipBehavior ?? Clip.antiAlias,
        child: result,
      );
    }
    return result;
  }

  if (notifier == null) return buildFor();

  // ThemeNotifier → MaterialApp qayta chiziladi → Theme.of(parent) yangilanadi.
  // Sheet ham shu notify'da qayta chizilsin.
  return ListenableBuilder(
    listenable: notifier,
    builder: (_, __) => buildFor(),
  );
}

/// Material bottom sheet — SDK navigator + **jonli** ProjectTheme.
Future<T?> showSdkModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool isDismissible = true,
  bool enableDrag = true,
  ShapeBorder? shape,
  Clip? clipBehavior,
  double? elevation,
  bool? showDragHandle,
  BoxConstraints? constraints,
}) {
  final notifier = _tryThemeNotifier(context);

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: false,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    shape: shape,
    clipBehavior: Clip.none,
    elevation: elevation ?? 0,
    showDragHandle: showDragHandle,
    constraints: constraints,
    builder: (_) => _wrapLiveTheme(
      parentContext: context,
      notifier: notifier,
      backgroundColor: backgroundColor,
      shape: shape,
      clipBehavior: clipBehavior,
      builder: builder,
    ),
  );
}

/// Cupertino modal popup — host root navigator'ga chiqmasin + jonli tema.
Future<T?> showSdkCupertinoModalPopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  ImageFilter? filter,
  Color? barrierColor,
  bool semanticsDismissible = false,
}) {
  final notifier = _tryThemeNotifier(context);

  Widget buildFor() => Theme(
        data: _pageTheme(context),
        child: Builder(builder: builder),
      );

  return showCupertinoModalPopup<T>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: barrierDismissible,
    filter: filter,
    barrierColor: barrierColor ?? kCupertinoModalBarrierColor,
    semanticsDismissible: semanticsDismissible,
    builder: (_) {
      if (notifier == null) return buildFor();
      return ListenableBuilder(
        listenable: notifier,
        builder: (_, __) => buildFor(),
      );
    },
  );
}

/// Flutter'ning `showCupertinoSheet`'i sheet'ni doim ROOT navigatorga push
/// qiladi — embed rejimda host navigatori. Bu wrapper SDK ichki navigatorda.
Future<T?> showSdkCupertinoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool enableDrag = true,
}) {
  return Navigator.of(context).push<T>(
    CupertinoSheetRoute<T>(
      enableDrag: enableDrag,
      scrollableBuilder: (BuildContext context, ScrollController controller) {
        return builder(context);
      },
    ),
  );
}
