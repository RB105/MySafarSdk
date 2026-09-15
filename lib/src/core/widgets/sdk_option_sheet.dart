import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/widgets/sdk_dialog.dart';

/// Tanlov sheet'idagi bitta variant (til, valyuta, mavzu va h.k.).
class SdkOptionItem<T> {
  const SdkOptionItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
  });

  final T value;
  final String title;
  final String? subtitle;

  /// Chapdagi belgi — bayroq yoki ikonka (taxminan 36×36).
  final Widget? leading;
}

/// Qisqa tanlov ro'yxati: sarlavha, yopish tugmasi va variantlar. Sheet
/// ichida [SdkSheetFrame] (tutqich, yumaloq burchak) bilan o'raladi.
class SdkOptionList<T> extends StatelessWidget {
  const SdkOptionList({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<SdkOptionItem<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final Color muted = context.isDarkMode
        ? ProjectTheme.secondaryTextDark
        : const Color(0xFF5B6475);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 13.5,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const SdkDialogCloseButton(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _OptionRow<T>(
                    item: options[i],
                    selected: options[i].value == selected,
                    muted: muted,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelected(options[i].value);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.item,
    required this.selected,
    required this.muted,
    required this.onTap,
  });

  final SdkOptionItem<T> item;
  final bool selected;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    final Color accent = isDark ? ProjectTheme.accentLight : brand;
    final Color border =
        isDark ? ProjectTheme.borderDark : ProjectTheme.borderLight;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : brand.withValues(alpha: 0.07))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: isDark ? 0.55 : 0.35)
                    : border.withValues(alpha: isDark ? 0.6 : 0.8),
              ),
            ),
            child: Row(
              children: [
                if (item.leading != null) ...[
                  SizedBox.square(
                    dimension: 36,
                    child: Center(child: item.leading),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      if (item.subtitle != null &&
                          item.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SdkRadioMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tanlov belgisi: tanlanganda brend rangli doira ichida belgi, aks holda
/// ingichka konturli bo'sh doira.
class SdkRadioMark extends StatelessWidget {
  const SdkRadioMark({super.key, required this.selected, this.size = 22});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color fill =
        isDark ? ProjectTheme.accentLight : ProjectTheme.brandColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? fill : Colors.transparent,
        border: selected
            ? null
            : Border.all(
                color:
                    isDark ? ProjectTheme.borderDark : ProjectTheme.borderLight,
                width: 1.5,
              ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: size * 0.68, color: Colors.white)
          : null,
    );
  }
}

/// Doira shaklidagi bayroq (png yoki svg) — til/valyuta variantlari uchun.
class SdkRoundFlag extends StatelessWidget {
  const SdkRoundFlag({super.key, required this.image, this.size = 32});

  /// Tayyor rasm vidjeti (masalan `Image.asset` / `SvgPicture.asset`).
  final Widget image;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: (context.isDarkMode ? Colors.white : Colors.black)
              .withValues(alpha: 0.08),
        ),
      ),
      child: ClipOval(child: SizedBox.expand(child: image)),
    );
  }
}
