import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';

/// Bron formalari uchun umumiy o'lcham va ranglar — yangi UI (yo'nalishlar
/// qidiruvi, segment tab) bilan bir xil: karta foni, 1px kontur, radius 14,
/// fokusda brend rang.
class BookingFormStyle {
  BookingFormStyle._();

  static const double radius = 14;

  /// Maydonning ENG KAM balandligi — katta tizim shriftida maydon o'sadi,
  /// matn kesilmaydi.
  static const double fieldHeight = 52;
  static const double labelGap = 6;

  static Color hint(BuildContext context) => context.isDarkMode
      ? ProjectTheme.secondaryTextDark.withValues(alpha: 0.6)
      : const Color(0xFF8A93A3);

  static Color label(BuildContext context) => context.isDarkMode
      ? ProjectTheme.secondaryTextDark
      : const Color(0xFF5B6475);

  static BoxDecoration box(
    BuildContext context, {
    bool focused = false,
    bool hasError = false,
  }) {
    final Color borderColor = hasError
        ? ProjectTheme.error
        : focused
            ? ProjectTheme.brandColor
            : context.color.outline;
    return BoxDecoration(
      color: context.color.primaryContainer,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor,
        width: hasError || focused ? 1.2 : 1,
      ),
    );
  }

  static TextStyle value(BuildContext context) =>
      context.textTheme.bodyMedium!.copyWith(fontSize: 16);
}

/// Maydon tepasidagi doimiy yorliq (suzuvchi emas — yozish paytida sakramaydi).
class BookingFieldLabel extends StatelessWidget {
  const BookingFieldLabel({
    super.key,
    required this.text,
    this.optional = false,
  });

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final base = context.textTheme.bodyMedium!.copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: BookingFormStyle.label(context),
    );
    return Padding(
      padding:
          const EdgeInsets.only(left: 2, bottom: BookingFormStyle.labelGap),
      child: Text.rich(
        TextSpan(
          text: text,
          style: base,
          children: [
            if (optional)
              TextSpan(
                text: ' · ${'optional'.tr()}',
                style: base.copyWith(
                  fontWeight: FontWeight.w500,
                  color: BookingFormStyle.hint(context),
                ),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Maydon ostidagi xato matni (bo'lmasa joy egallamaydi).
class BookingFieldError extends StatelessWidget {
  const BookingFieldError({super.key, required this.text});

  final String? text;

  /// Xato matni ochilish animatsiyasi — scroll shu tugagach boshlanadi.
  static const Duration animationDuration = Duration(milliseconds: 160);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: animationDuration,
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: (text == null || text!.isEmpty)
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(left: 2, top: 6),
              child: Text(
                text!,
                style: context.textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: ProjectTheme.error,
                ),
              ),
            ),
    );
  }
}

/// Matn maydoni: yorliq tepada, ingichka kontur, xato ostida.
///
/// Tavsiyalar faqat foydalanuvchi yoza boshlaganda va mos keladigan qiymat
/// bo'lsagina chiqadi (ko'pi bilan 3 ta) — bo'sh maydonga fokus berilganda
/// ro'yxat ochilib chalg'itmaydi.
class BookingTextField extends StatefulWidget {
  const BookingTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.showError,
    this.validator,
    this.optional = false,
    this.hintText,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.suffix,
    this.suggestions = const [],
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool showError;
  final String? Function(String value)? validator;
  final bool optional;
  final String? hintText;
  final VoidCallback? onSubmitted;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final List<String> suggestions;

  /// Tizim avtoto'ldirishi uchun ([AutofillHints.email] va h.k.).
  final Iterable<String>? autofillHints;

  static const int _maxSuggestions = 3;

  @override
  State<BookingTextField> createState() => _BookingTextFieldState();
}

class _BookingTextFieldState extends State<BookingTextField> {
  double _fieldWidth = 0;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_rebuild);
    widget.controller.addListener(_onControllerChanged);
    _syncMaskFormatters();
  }

  @override
  void didUpdateWidget(BookingTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_rebuild);
      widget.focusNode.addListener(_rebuild);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    _syncMaskFormatters();
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_rebuild);
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onControllerChanged() {
    _syncMaskFormatters();
    _rebuild();
  }

  /// Matn koddan o'rnatilganda (skaner, saqlangan yo'lovchi, kalendar,
  /// dastlabki to'ldirish) [MaskTextInputFormatter] buni ko'rmaydi va ichki
  /// holati bo'sh qoladi — keyingi backspace butun maydonni tozalab yuboradi.
  /// Shuning uchun formatter holatini controller matniga moslaymiz.
  /// Foydalanuvchi yozganda matn formatter orqali o'tadi — o'zgarish yo'q.
  void _syncMaskFormatters() {
    final formatters = widget.inputFormatters;
    if (formatters == null) return;
    final text = widget.controller.text;
    for (final formatter in formatters.whereType<MaskTextInputFormatter>()) {
      if (formatter.getMaskedText() == text) continue;
      if (text.isEmpty) {
        formatter.clear();
      } else {
        formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: formatter.unmaskText(text)),
        );
      }
    }
  }

  Iterable<String> _options(TextEditingValue value) {
    final query = value.text.trim().toUpperCase();
    if (query.isEmpty) return const [];
    return widget.suggestions.where((option) {
      final upper = option.toUpperCase();
      return upper.startsWith(query) && upper != query;
    }).take(BookingTextField._maxSuggestions);
  }

  /// Tavsiya tanlanganda qiymat maydon formatter'laridan o'tadi (mask
  /// formatter'ning ichki holati ham yangilanadi — aks holda keyingi tahrirda
  /// mask noto'g'ri ishlaydi).
  ///
  /// Faqat raqam qabul qiladigan mask'ga raqamlar beriladi; boshqa
  /// formatter'larga (hujjat raqami, ism) qiymat TO'LIQ beriladi — ilgari
  /// "AA1234567" tanlansa seriya harflari tushib qolardi (№67).
  void _onSelected(String option) {
    var value = TextEditingValue(text: option);
    for (final formatter in widget.inputFormatters ?? const []) {
      if (formatter is MaskTextInputFormatter) {
        final digits = option.replaceAll(RegExp(r'[^0-9]'), '');
        value = formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: digits.isNotEmpty ? digits : option),
        );
      } else {
        value = formatter.formatEditUpdate(TextEditingValue.empty, value);
      }
    }
    widget.controller.value = value.copyWith(
        selection: TextSelection.collapsed(offset: value.text.length));
    widget.onChanged(value.text);
    widget.onSubmitted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final String? error = widget.showError
        ? widget.validator?.call(widget.controller.text)
        : null;
    final bool hasError = error != null && error.isNotEmpty;
    final bool focused = widget.focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BookingFieldLabel(text: widget.label, optional: widget.optional),
        LayoutBuilder(
          builder: (context, constraints) {
            _fieldWidth = constraints.maxWidth;
            return RawAutocomplete<String>(
              textEditingController: widget.controller,
              focusNode: widget.focusNode,
              optionsBuilder: _options,
              onSelected: _onSelected,
              fieldViewBuilder: (context, controller, focusNode, _) =>
                  AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(
                    minHeight: BookingFormStyle.fieldHeight),
                decoration: BookingFormStyle.box(
                  context,
                  focused: focused,
                  hasError: hasError,
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: BookingFormStyle.value(context),
                  cursorColor: ProjectTheme.brandColor,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  inputFormatters: widget.inputFormatters,
                  autofillHints: widget.autofillHints,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => widget.onSubmitted?.call(),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: BookingFormStyle.value(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: BookingFormStyle.hint(context),
                    ),
                    contentPadding: EdgeInsets.fromLTRB(
                        14, 15, widget.suffix == null ? 14 : 4, 15),
                    suffixIcon: widget.suffix,
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ),
              ),
              // Klaviatura ochiq, maydon pastda bo'lsa ostida joy qolmaydi —
              // ro'yxat joy ko'proq tomonga (kerak bo'lsa tepaga) ochiladi.
              optionsViewOpenDirection: OptionsViewOpenDirection.mostSpace,
              // Tomonga moslash (tepaga/pastga) RawAutocomplete'ning o'zida;
              // vertikal padding ikkala holatda ham maydondan 6px oraliq beradi.
              optionsViewBuilder: (context, onSelected, options) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Material(
                  elevation: 3,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                  color: context.color.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(BookingFormStyle.radius),
                    side: BorderSide(color: context.color.outline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: _fieldWidth,
                    // Joy tavsiyalarga yetmasa (kichik ekran + klaviatura)
                    // overflow o'rniga ro'yxat ichida scroll bo'ladi.
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final option in options)
                          InkWell(
                            onTap: () => onSelected(option),
                            child: Container(
                              height: 46,
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                option,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BookingFormStyle.value(context),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        BookingFieldError(text: error),
      ],
    );
  }
}

/// Bosiladigan tanlash maydoni (masalan fuqarolik) — matn maydoni bilan bir
/// xil ko'rinishda, o'ngda pastga strelka.
class BookingPickerField extends StatelessWidget {
  const BookingPickerField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
    required this.chevronAsset,
    this.value,
    this.leading,
    this.errorText,
    this.focusNode,
  });

  final String label;
  final String placeholder;
  final String? value;
  final Widget? leading;
  final String? errorText;
  final VoidCallback onTap;
  final String chevronAsset;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.isNotEmpty;
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BookingFieldLabel(text: label),
        Focus(
          focusNode: focusNode,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(BookingFormStyle.radius),
            clipBehavior: Clip.antiAlias,
            child: Semantics(
              button: true,
              label: label,
              child: InkWell(
                onTap: onTap,
                child: Ink(
                  decoration: BookingFormStyle.box(context, hasError: hasError),
                  child: Container(
                    constraints: const BoxConstraints(
                        minHeight: BookingFormStyle.fieldHeight),
                    padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                    child: Row(
                      children: [
                        if (hasValue && leading != null) ...[
                          leading!,
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            hasValue ? value! : placeholder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: hasValue
                                ? BookingFormStyle.value(context)
                                : BookingFormStyle.value(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: BookingFormStyle.hint(context),
                                  ),
                          ),
                        ),
                        SvgPicture.asset(
                          chevronAsset,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            BookingFormStyle.hint(context),
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        BookingFieldError(text: errorText),
      ],
    );
  }
}

/// Ikki-uch variantli tanlagich (masalan jins) — karta foni, 1px kontur va
/// tanlangan variant ostida suriladigan brend "pill" (segment tab bilan bir
/// xil uslub).
class BookingChoiceField<T> extends StatelessWidget {
  const BookingChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Hech narsa tanlanmagan bo'lsa ko'rsatiladigan xato (masalan jins).
  final String? errorText;

  static const double _height = 48;
  static const double _padding = 4;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color brand = ProjectTheme.brandColor;
    final Color inactive = isDark
        ? ProjectTheme.secondaryTextDark
        : ProjectTheme.secondaryTextLight;
    final int selected = options.indexWhere((o) => o.$1 == value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BookingFieldLabel(text: label),
        Container(
          // Katta tizim shriftida matn sig'ishi uchun balandlik o'sadi.
          height: _height +
              (MediaQuery.textScalerOf(context).scale(15) - 15)
                  .clamp(0.0, 40.0),
          padding: const EdgeInsets.all(_padding),
          decoration: BookingFormStyle.box(
            context,
            hasError: errorText != null && errorText!.isNotEmpty,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = constraints.maxWidth / options.length;
              return Stack(
                children: [
                  if (selected >= 0)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * selected,
                      width: itemWidth,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: brand,
                          borderRadius: BorderRadius.circular(
                              BookingFormStyle.radius - _padding),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  brand.withValues(alpha: isDark ? 0.30 : 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      for (int i = 0; i < options.length; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: i == selected,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (i == selected) return;
                                HapticFeedback.selectionClick();
                                onChanged(options[i].$1);
                              },
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  style: TextStyle(
                                    fontFamily: 'packages/mysafar_sdk/Gilroy',
                                    fontSize: 15,
                                    fontWeight: i == selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color:
                                        i == selected ? Colors.white : inactive,
                                  ),
                                  child: Text(
                                    options[i].$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        BookingFieldError(text: errorText),
      ],
    );
  }
}
