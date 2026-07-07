/*
 *  (c) Diyor Xalloqov 2024.8.15 Toshkent, Uzbekistan
 *  github: https://github.com/diyorxalloqov
 *  LinkedIn: https://www.linkedin.com/in/diyor-xalloqov-024b63231/
 *  Telegram: https://t.me/Flutter_dart_developer
 */

import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/styles/theme_notifier.dart' show ThemeNotifier;
import 'package:mysafar_sdk/src/view/imports/app_imports.dart';
import 'package:provider/provider.dart' show Provider;

class TextFormFieldWidget extends StatefulWidget {
  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? prefixIcon;
  final String? suffixText;
  final TextEditingController? controller;
  final TextInputType? type;
  final bool? readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final TextStyle? hintStyle;
  final bool? obscureText;
  final String? obscuringCharacter;
  final BoxConstraints? constraints;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final int? maxLines;
  final EdgeInsets? contentPadding;
  final TextStyle? style;
  final FocusNode? focusNode;
  final bool? enabled;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;

  const TextFormFieldWidget(
      {super.key,
      this.hintText,
      this.controller,
      this.suffixIcon,
      this.prefix,
      this.type,
      this.suffix,
      this.prefixIcon,
      this.suffixText,
      this.readOnly,
      this.onTap,
      this.maxLength,
      this.hintStyle,
      this.obscureText,
      this.obscuringCharacter,
      this.constraints,
      this.validator,
      this.onChanged,
      this.onFieldSubmitted,
      this.maxLines,
      this.contentPadding,
      this.style,
      this.errorText,
      this.inputFormatters,
      this.enabled,
      this.focusNode});

  @override
  State<TextFormFieldWidget> createState() => _TextFormFieldWidgetState();
}

class _TextFormFieldWidgetState extends State<TextFormFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: widget.style ?? ProjectTheme.textLightStyle,
      cursorColor: Provider.of<ThemeNotifier>(context).isDark
          ? ProjectTheme.white
          : ProjectTheme.black,
      keyboardType: widget.type,
      controller: widget.controller,
      validator: (value) {
        final result = widget.validator?.call(value);
        return result;
      },
      onTap: widget.onTap,
      maxLength: widget.maxLength,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      readOnly: widget.readOnly ?? false,
      maxLines: widget.maxLines ?? 1,
      enabled: widget.enabled,
      keyboardAppearance: Theme.of(context).brightness,
      obscureText: widget.obscureText ?? false,
      obscuringCharacter: widget.obscuringCharacter ?? '*',
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              strokeAlign: 1,
              width: 1.5,
              color: context.color.outline,
            ),
            borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              strokeAlign: 1,
              width: 1.5,
              color: ProjectTheme.brandColor,
            )),
        border: OutlineInputBorder(
            borderSide: BorderSide(
                strokeAlign: 1, width: 1.5, color: context.color.outline),
            borderRadius: BorderRadius.circular(8)),
        errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              strokeAlign: 1,
              width: 1,
              color: Color(0xffEF2323),
            ),
            borderRadius: BorderRadius.circular(8)),
        hintText: widget.hintText,
        suffixIcon: widget.suffixIcon,
        suffixText: widget.suffixText,
        errorText: widget.errorText,
        contentPadding: widget.contentPadding,
        counterText: '',
        errorMaxLines: 2,
        prefixIcon: widget.prefixIcon,
        prefix: widget.prefix,
        suffix: widget.suffix,
        hintStyle: widget.hintStyle,
      ),
    );
  }
}
