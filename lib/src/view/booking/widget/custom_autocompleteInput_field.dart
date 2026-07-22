// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'custom_input_field_widget.dart';

class CustomAutocompleteInputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final List<String> suggestions;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final Widget? perfex;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final bool showError;
  final ValueChanged<String>? onSuggestionSelected;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;

  const CustomAutocompleteInputField({
    super.key,
    required this.label,
    this.hintText,
    required this.controller,
    required this.suggestions,
    this.validator,
    this.onChanged,
    this.perfex,
    this.keyboardType,
    this.inputFormatters,
    this.suffix,
    required this.textCapitalization,
    required this.textInputAction,
    required this.showError,
    this.onSuggestionSelected,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  State<CustomAutocompleteInputField> createState() =>
      _CustomAutocompleteInputFieldState();
}

class _CustomAutocompleteInputFieldState
    extends State<CustomAutocompleteInputField> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      focusNode: _focusNode,
      textEditingController: widget.controller,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return widget.suggestions;
        }
        return widget.suggestions.where((String option) {
          return option.contains(textEditingValue.text);
        });
      },
        onSelected: (String option) {
          TextEditingValue value = TextEditingValue(text: option);
          if (widget.inputFormatters != null &&
              widget.inputFormatters!.isNotEmpty) {
            for (final formatter in widget.inputFormatters!) {
              final rawDigits = option.replaceAll(RegExp(r'[^0-9]'), '');
              value = formatter.formatEditUpdate(
                const TextEditingValue(),
                TextEditingValue(text: rawDigits.isNotEmpty ? rawDigits : option),
              );
              break;
            }
          }

          widget.controller.value = value;

          if (widget.onChanged != null) {
            widget.onChanged!(value.text);
          }
        },

        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return CustomInputField(
          suffix: widget.suffix,
          label: widget.label,
          hintText: widget.hintText,
          controller: controller,
          validator: widget.validator,
          onChanged: widget.onChanged,
          perfex: widget.perfex,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,
          showError: widget.showError,
          focusNode: focusNode,
          onFieldSubmitted: (_) {
            widget.onFieldSubmitted?.call('');
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 3,
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width * 0.85,
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
