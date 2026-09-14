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
  AnimationStyle? sheetAnimationStyle,
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
    sheetAnimationStyle: sheetAnimationStyle,
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

/// To'liq balandlikdagi SDK sheet'ining yuqori burchak radiusi.
const double kSdkSheetTopRadius = 36;

/// Status bar ostidan boshlanadigan to'liq balandlikdagi sheet — iOS va
/// Android'da bir xil ko'rinish (katta yumaloq burchaklar).
///
/// Yopish: sarlavhani yoki ro'yxat eng tepada turganda kontentni pastga
/// tortish (chorakdan o'tsa yoki tez silkitilsa yopiladi, aks holda qaytadi).
/// Ro'yxat [builder]ga berilgan `controller`ni ishlatishi shart.
Future<T?> showSdkFullHeightSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, ScrollController controller)
      builder,
}) {
  return showSdkModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Tortish [_SdkFullHeightSheet] ichida boshqariladi.
    enableDrag: false,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 380),
      reverseDuration: Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    ),
    builder: (_) => _SdkFullHeightSheet(builder: builder),
  );
}

class _SdkFullHeightSheet extends StatefulWidget {
  const _SdkFullHeightSheet({required this.builder});

  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  @override
  State<_SdkFullHeightSheet> createState() => _SdkFullHeightSheetState();
}

class _SdkFullHeightSheetState extends State<_SdkFullHeightSheet> {
  /// Qo'yib yuborilganda shundan pastda bo'lsa — yopiladi.
  static const double _closeBelowSize = 0.75;

  /// Shundan tez pastga silkitilsa (px/s) — masofadan qat'i nazar yopiladi.
  static const double _closeFlingVelocity = 700;

  final DraggableScrollableController _controller =
      DraggableScrollableController();
  double _height = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double size) {
    if (!_controller.isAttached) return;
    _controller.animateTo(
      size,
      duration: Duration(milliseconds: size == 0 ? 220 : 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Sarlavha / qidiruv maydonini tortish (ro'yxatdan tashqari joy).
  void _onHeaderDrag(DragUpdateDetails details) {
    if (!_controller.isAttached) return;
    final size = _controller.size - (details.primaryDelta ?? 0) / _height;
    _controller.jumpTo(size.clamp(0.0, 1.0));
  }

  void _onHeaderDragEnd(DragEndDetails details) {
    if (!_controller.isAttached || _controller.size >= 1) return;
    final velocity = details.primaryVelocity ?? 0;
    final close =
        velocity > _closeFlingVelocity || _controller.size < _closeBelowSize;
    _animateTo(close ? 0 : 1);
  }

  /// Ro'yxat tortib qo'yib yuborilganda sekin qo'yilsa ham yopish. Tez
  /// silkitish va qaytishni `snap` o'zi hal qiladi. Microtask — drag'ning
  /// o'z `goBallistic`idan keyin ishlashi uchun.
  void _onPointerUp(PointerUpEvent _) {
    Future.microtask(() {
      if (!mounted || !_controller.isAttached) return;
      if (_controller.size < _closeBelowSize) _animateTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fill = context.isDarkMode
        ? ProjectTheme.cardColorDark
        : ProjectTheme.cardColorLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        _height = constraints.maxHeight;
        return DraggableScrollableSheet(
          controller: _controller,
          initialChildSize: 1,
          minChildSize: 0,
          maxChildSize: 1,
          snap: true,
          builder: (context, scrollController) => ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(kSdkSheetTopRadius),
            ),
            // Kontent doim to'liq balandlikda chiziladi — sheet pastga
            // tortilganda siqilmaydi (overflow yo'q), faqat pastga suriladi.
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: _height,
              maxHeight: _height,
              child: Listener(
                onPointerUp: _onPointerUp,
                // Ro'yxatning o'z drag'i arena'da yutadi — bu faqat
                // ro'yxatdan tashqaridagi joylarni tortganda ishlaydi.
                child: GestureDetector(
                  onVerticalDragUpdate: _onHeaderDrag,
                  onVerticalDragEnd: _onHeaderDragEnd,
                  child: Material(
                    color: fill,
                    child: widget.builder(context, scrollController),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
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
