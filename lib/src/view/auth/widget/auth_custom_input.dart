import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';

class AuthCustomInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final Widget? perfex;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final bool showError;
  final FocusNode? focusNode;

  const AuthCustomInputField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.onChanged,
    this.perfex,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    required this.textCapitalization,
    required this.textInputAction,
    required this.showError,
    this.focusNode,
  });

  @override
  State<AuthCustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<AuthCustomInputField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.onChanged != null) {
      widget.controller.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    widget.controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool shouldShowLabel =
        _focusNode.hasFocus || widget.controller.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 56,
              child: TextFormField(
                style: context.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
                cursorHeight: 16,
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  setState(() {});
                },
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                textCapitalization: widget.textCapitalization,
                textInputAction: widget.textInputAction,
                validator: widget.validator,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.themeProvider.isDark
                      ? context.theme.primaryColor
                      : Color(0xffF2F3F5),
                  suffixIcon: widget.suffix,
                  isDense: true,
                  contentPadding: const EdgeInsets.only(
                      bottom: 16, left: 16, right: 16, top: 28),
                  prefixIcon: shouldShowLabel
                      ? widget.perfex != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: SizedBox(height: 24, child: widget.perfex),
                            )
                          : null
                      : null,
                  hintText: shouldShowLabel ? null : widget.label,
                  hintStyle: context.textTheme.headlineSmall
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        strokeAlign: 1,
                        width: 0,
                        color: context.color.outline,
                      ),
                      borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        strokeAlign: 1,
                        width: 0,
                        color: context.color.outline,
                      )),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(
                          strokeAlign: 1,
                          width: 0,
                          color: context.color.outline),
                      borderRadius: BorderRadius.circular(16)),
                  errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        strokeAlign: 1,
                        width: 0,
                        color: context.color.outline,
                      ),
                      borderRadius: BorderRadius.circular(16)),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
              ),
            ),
            if (shouldShowLabel)
              Positioned(
                left: 16,
                top: 4,
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E92),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
