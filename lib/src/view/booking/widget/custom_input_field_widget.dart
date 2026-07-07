import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? perfex;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final bool showError;
  final FocusNode? focusNode;

  /// Yorliq tepaga suzilganda (maydon fokusda va bo'sh) ko'rsatiladigan
  /// ixtiyoriy ko'rsatma — mas. sana maydonlari uchun "Kun / Oy / Yil".
  final String? hintText;


  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.perfex,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    required this.textCapitalization,
    required this.textInputAction,
    required this.showError,
    this.focusNode,
    this.hintText,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late FocusNode _focusNode;
  bool _controllerListenerAdded = false;

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
    if (widget.onChanged != null) {
      widget.controller.addListener(_onControllerChanged);
      _controllerListenerAdded = true;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (_controllerListenerAdded) {
      widget.controller.removeListener(_onControllerChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool shouldShowLabel =
        _focusNode.hasFocus || widget.controller.text.isNotEmpty;
    String? errorText = widget.showError && widget.controller.text.isEmpty
        ? widget.validator?.call(widget.controller.text)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 56,
              child: TextFormField(
                style: context.textTheme.bodyMedium,
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
                onFieldSubmitted: widget.onFieldSubmitted,
                validator: widget.validator,
                decoration: InputDecoration(
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
                  // Yorliq tepaga suzilganda (fokus yoki to'ldirilgan) va maydon
                  // bo'sh bo'lsa — format ko'rsatmasini ("Kun / Oy / Yil")
                  // ko'rsatamiz; fokussiz va bo'sh bo'lsa yorliqning o'zi
                  // placeholder bo'lib turadi.
                  hintText: shouldShowLabel
                      ? (widget.controller.text.isEmpty ? widget.hintText : null)
                      : widget.label,
                  hintStyle: context.textTheme.headlineSmall
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        strokeAlign: 1,
                        width: 1.5,
                        color: context.color.outline,
                      ),
                      borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        strokeAlign: 1,
                        width: 1.5,
                        color: ProjectTheme.brandColor,
                      )),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(
                          strokeAlign: 1,
                          width: 1.5,
                          color: context.color.outline),
                      borderRadius: BorderRadius.circular(16)),
                  errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        strokeAlign: 1,
                        width: 1,
                        color: Color(0xffEF2323),
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
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          )
      ],
    );
  }
}
