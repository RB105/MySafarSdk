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
/// Rang manbai — sheet ichidagi [BuildContext] (yoki ochilishdagi fallback),
/// deactivate bo'lgan parent contextga qayta murojaat qilinmaydi.

ThemeNotifier? _tryThemeNotifier(BuildContext context) {
  try {
    return context.themeProvider;
  } catch (_) {
    return null;
  }
}

/// Context hali tree'da bo'lsa undan brightness olinadi; aks holda
/// [ThemeNotifier] yoki light fallback.
ThemeData _resolveTheme({
  required BuildContext? liveContext,
  required ThemeNotifier? notifier,
  required ThemeData fallback,
}) {
  if (liveContext != null && liveContext.mounted) {
    try {
      final isDark = Theme.of(liveContext).brightness == Brightness.dark;
      return isDark ? ProjectTheme.dark : ProjectTheme.light;
    } catch (_) {
      // Deactivated / InheritedWidget yo'q — pastdagi fallback.
    }
  }
  if (notifier != null) {
    return notifier.isDark ? ProjectTheme.dark : ProjectTheme.light;
  }
  return fallback;
}

Color? _sheetFill({
  required Color? backgroundColor,
  required ThemeData theme,
}) {
  if (backgroundColor == Colors.transparent) return null;
  final isDark = theme.brightness == Brightness.dark;
  return isDark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight;
}

Widget _wrapLiveTheme({
  required ThemeData initialTheme,
  required ThemeNotifier? notifier,
  required Color? backgroundColor,
  required ShapeBorder? shape,
  required Clip? clipBehavior,
  required WidgetBuilder builder,
}) {
  Widget buildFor(BuildContext sheetContext) {
    final theme = _resolveTheme(
      liveContext: sheetContext,
      notifier: notifier,
      fallback: initialTheme,
    );
    final fill = _sheetFill(backgroundColor: backgroundColor, theme: theme);
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

  if (notifier == null) {
    return Builder(builder: buildFor);
  }

  // ThemeNotifier → sheet qayta chizilsin. Temani sheetContext yoki
  // notifier'dan olamiz — ochilishdagi parentContextga qayta tegmaymiz
  // (u deactivate bo'lishi mumkin: sheet ustiga push / pop).
  return ListenableBuilder(
    listenable: notifier,
    builder: (sheetContext, _) => buildFor(sheetContext),
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
  // Ochilish paytidagi tema — keyin parent deactivate bo'lsa fallback.
  final initialTheme = _resolveTheme(
    liveContext: context,
    notifier: notifier,
    fallback: ProjectTheme.light,
  );

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
      initialTheme: initialTheme,
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
  final initialTheme = _resolveTheme(
    liveContext: context,
    notifier: notifier,
    fallback: ProjectTheme.light,
  );

  Widget buildFor(BuildContext sheetContext) => Theme(
        data: _resolveTheme(
          liveContext: sheetContext,
          notifier: notifier,
          fallback: initialTheme,
        ),
        child: Builder(builder: builder),
      );

  return showCupertinoModalPopup<T>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: barrierDismissible,
    filter: filter,
    barrierColor: barrierColor ?? kCupertinoModalBarrierColor,
    semanticsDismissible: semanticsDismissible,
    builder: (sheetContext) {
      if (notifier == null) return buildFor(sheetContext);
      return ListenableBuilder(
        listenable: notifier,
        builder: (ctx, _) => buildFor(ctx),
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
