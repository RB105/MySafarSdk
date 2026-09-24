import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/sdk_sheets.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';

/// SDK bo'ylab info / xato / tasdiqlash dialoglari va sheet'lari uchun
/// umumiy ko'rinish: rangli belgi (badge), sarlavha, izoh va tugmalar.

/// Dialog ohangi — belgi rangi va standart ikonka shunga qarab tanlanadi.
enum SdkDialogTone {
  success,
  error,
  warning,
  info;

  Color color(BuildContext context) {
    final base = switch (this) {
      SdkDialogTone.success => ProjectTheme.success,
      SdkDialogTone.error => ProjectTheme.error,
      SdkDialogTone.warning => ProjectTheme.accentOrange,
      SdkDialogTone.info => ProjectTheme.brandColor,
    };
    // Dark fonda to'q ranglar halo ichida yo'qolib qoladi — biroz yoritamiz.
    if (!context.isDarkMode) return base;
    final lift = this == SdkDialogTone.info ? 0.35 : 0.2;
    return Color.lerp(base, Colors.white, lift)!;
  }

  String get defaultIcon => switch (this) {
        SdkDialogTone.success => Assets.iconsDialogSuccessIcon,
        SdkDialogTone.error => Assets.iconsDialogErrorIcon,
        SdkDialogTone.warning => Assets.iconsDialogWarningIcon,
        SdkDialogTone.info => Assets.iconsDialogInfoIcon,
      };
}

enum SdkDialogButtonVariant { primary, secondary, danger, dangerSoft }

class SdkDialogAction<T> {
  const SdkDialogAction({
    required this.label,
    this.value,
    this.variant = SdkDialogButtonVariant.primary,
    this.onTap,
  });

  final String label;

  /// [onTap] berilmasa dialog shu qiymat bilan yopiladi.
  final T? value;
  final SdkDialogButtonVariant variant;

  /// Berilsa dialog avtomatik YOPILMAYDI — yopish chaqiruvchining zimmasida.
  final void Function(BuildContext dialogContext)? onTap;
}

Color _cardColor(BuildContext context) => context.isDarkMode
    ? ProjectTheme.cardColorDark
    : ProjectTheme.cardColorLight;

Color _secondaryText(BuildContext context) => context.isDarkMode
    ? ProjectTheme.secondaryTextDark
    : ProjectTheme.secondaryTextLight;

/// Neytral yuza (ikkinchi darajali tugma, info blok, yopish tugmasi).
Color sdkDialogMutedFill(BuildContext context) => context.isDarkMode
    ? Colors.white.withValues(alpha: 0.08)
    : const Color(0xFFF1F4F9);

/// Ikki qavatli halo ichidagi rangli ikonka — ochilishda yumshoq "pop".
class SdkDialogBadge extends StatelessWidget {
  const SdkDialogBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 76,
  });

  final String icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: isDark ? 0.10 : 0.08),
        ),
        child: Container(
          width: size * 0.72,
          height: size * 0.72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isDark ? 0.16 : 0.14),
          ),
          child: SvgPicture.asset(
            icon,
            width: size * 0.46,
            height: size * 0.46,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class SdkDialogButton extends StatelessWidget {
  const SdkDialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SdkDialogButtonVariant.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final SdkDialogButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final (Color bg, Color fg) = switch (variant) {
      SdkDialogButtonVariant.primary => (ProjectTheme.brandColor, Colors.white),
      SdkDialogButtonVariant.secondary => (
          sdkDialogMutedFill(context),
          isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight,
        ),
      SdkDialogButtonVariant.danger => (ProjectTheme.error, Colors.white),
      SdkDialogButtonVariant.dangerSoft => (
          ProjectTheme.error.withValues(alpha: isDark ? 0.18 : 0.08),
          isDark ? const Color(0xFFFF6B61) : ProjectTheme.error,
        ),
    };

    return ConstrainedBox(
      // Katta shriftda matn sig'ishi uchun balandlik qat'iy emas (№32).
      constraints:
          const BoxConstraints(minWidth: double.infinity, minHeight: 52),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: fg,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Dialog va sheet uchun umumiy tarkib. Sarlavha/izoh/[content] qismi
/// balandlik yetmasa scroll bo'ladi; belgi va tugmalar doim ko'rinadi.
class SdkDialogBody<T> extends StatelessWidget {
  const SdkDialogBody({
    super.key,
    this.icon,
    this.tone = SdkDialogTone.info,
    this.title,
    this.message,
    this.content,
    this.actions = const [],
  });

  final String? icon;
  final SdkDialogTone tone;
  final String? title;
  final String? message;
  final Widget? content;
  final List<SdkDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title?.trim().isNotEmpty == true;
    final hasMessage = message?.trim().isNotEmpty == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SdkDialogBadge(
          icon: icon ?? tone.defaultIcon,
          color: tone.color(context),
        ),
        const SizedBox(height: 18),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasTitle)
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                if (hasTitle && hasMessage) const SizedBox(height: 8),
                if (hasMessage)
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    // Sarlavha bo'lmasa xabarning o'zi asosiy matn.
                    style: hasTitle
                        ? context.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                            color: _secondaryText(context),
                          )
                        : context.textTheme.bodyMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                  ),
                if (content != null) ...[
                  const SizedBox(height: 16),
                  content!,
                ],
              ],
            ),
          ),
        ),
        if (actions.isNotEmpty) const SizedBox(height: 24),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          SdkDialogButton(
            label: actions[i].label,
            variant: actions[i].variant,
            onPressed: () {
              final action = actions[i];
              if (action.onTap != null) {
                action.onTap!(context);
              } else {
                Navigator.of(context).pop(action.value);
              }
            },
          ),
        ],
      ],
    );
  }
}

class SdkDialogCloseButton extends StatelessWidget {
  const SdkDialogCloseButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final VoidCallback handleTap = onTap ?? () => Navigator.of(context).pop();
    // Ko'rinishi 34 dp doira, bosish maydoni 44 dp (№32); ekran o'quvchi
    // uchun "Yopish" nomi.
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).closeButtonTooltip,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: handleTap,
        child: SizedBox.square(
          dimension: 44,
          child: Center(child: _circle(context, handleTap)),
        ),
      ),
    );
  }

  Widget _circle(BuildContext context, VoidCallback handleTap) {
    return Material(
      color: sdkDialogMutedFill(context),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: handleTap,
        child: SizedBox.square(
          dimension: 34,
          child: Center(
            child: SvgPicture.asset(
              Assets.iconsPlaceCloseIcon,
              width: 18,
              height: 18,
              colorFilter:
                  ColorFilter.mode(_secondaryText(context), BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

/// Markazdagi dialog kartasi.
class SdkDialogCard extends StatelessWidget {
  const SdkDialogCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _cardColor(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Pastga yopishgan sheet ramkasi — tortish tutqichi, ixtiyoriy yopish
/// tugmasi va pastki xavfsiz hudud.
class SdkSheetFrame extends StatelessWidget {
  const SdkSheetFrame({
    super.key,
    required this.child,
    this.showHandle = true,
    this.showCloseButton = false,
  });

  final Widget child;
  final bool showHandle;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: _cardColor(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, showHandle ? 10 : 28, 20, 16 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHandle) ...[
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _secondaryText(context).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Flexible(child: child),
              ],
            ),
          ),
          if (showCloseButton)
            // 44 dp bosish maydoni: ko'rinadigan doira avvalgidek 14 dp da.
            const Positioned(top: 9, right: 9, child: SdkDialogCloseButton()),
        ],
      ),
    );
  }
}

/// Markaziy alert dialog. [onBuild] — dialog contextini tashqarida saqlash
/// kerak bo'lsa (masalan `ProjectDialogs.dismissCurrentDialog`).
Future<T?> showSdkAlert<T>({
  required BuildContext context,
  String? icon,
  SdkDialogTone tone = SdkDialogTone.info,
  String? title,
  String? message,
  Widget? content,
  List<SdkDialogAction<T>> actions = const [],
  bool barrierDismissible = true,
  bool canPop = true,
  void Function(BuildContext dialogContext)? onBuild,
}) {
  return showDialog<T>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (dialogContext) {
      onBuild?.call(dialogContext);
      return PopScope(
        canPop: canPop,
        child: SdkDialogCard(
          child: SdkDialogBody<T>(
            icon: icon,
            tone: tone,
            title: title,
            message: message,
            content: content,
            actions: actions,
          ),
        ),
      );
    },
  );
}

/// Pastdan chiqadigan alert sheet — [showSdkAlert] bilan bir xil tarkib.
Future<T?> showSdkSheetAlert<T>({
  required BuildContext context,
  String? icon,
  SdkDialogTone tone = SdkDialogTone.info,
  String? title,
  String? message,
  Widget? content,
  List<SdkDialogAction<T>> actions = const [],
  bool isDismissible = true,
  bool enableDrag = true,
  bool showCloseButton = false,
  void Function(BuildContext sheetContext)? onBuild,
}) {
  return showSdkModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (sheetContext) {
      onBuild?.call(sheetContext);
      return SdkSheetFrame(
        showHandle: enableDrag,
        showCloseButton: showCloseButton,
        child: SdkDialogBody<T>(
          icon: icon,
          tone: tone,
          title: title,
          message: message,
          content: content,
          actions: actions,
        ),
      );
    },
  );
}

/// Kichik yuklanish kartasi — brend rangdagi spinner (dialog yoki overlay
/// ichida ishlatiladi).
class SdkLoadingCard extends StatelessWidget {
  const SdkLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _cardColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(ProjectTheme.brandColor),
        ),
      ),
    );
  }
}

/// Yopib bo'lmaydigan yuklanish dialogi. Yopish — chaqiruvchi
/// `Navigator.pop` qiladi (yoki [onBuild] orqali olingan context bilan).
Future<void> showSdkLoader(
  BuildContext context, {
  void Function(BuildContext dialogContext)? onBuild,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) {
      onBuild?.call(dialogContext);
      return const PopScope(canPop: false, child: SdkLoadingCard());
    },
  );
}
