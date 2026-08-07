import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/view/booking/widget/passenger_date_picker.dart';

class CalendarPickerContainer extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime? initialDate;
  final String title;
  final TextEditingController? controller;
  final bool isFutureOnly;

  const CalendarPickerContainer({
    super.key,
    required this.onDateSelected,
    this.initialDate,
    required this.title,
    this.controller,
    this.isFutureOnly = false,
  });

  @override
  State<CalendarPickerContainer> createState() =>
      _CalendarPickerContainerState();
}

class _CalendarPickerContainerState extends State<CalendarPickerContainer> {
  DateTime? selectedDate;

  void _showDatePicker() {
    final controller = widget.controller ?? TextEditingController();
    if (selectedDate != null && controller.text.isEmpty) {
      controller.text = DateFormat('dd.MM.yyyy').format(selectedDate!);
    } else if (widget.initialDate != null && controller.text.isEmpty) {
      controller.text = DateFormat('dd.MM.yyyy').format(widget.initialDate!);
    }

    PassengerDatePicker.show(
      context: context,
      controller: controller,
      isFutureOnly: widget.isFutureOnly,
      initialDate: widget.initialDate,
      title: widget.title,
      onDateSelected: (date) {
        setState(() => selectedDate = date);
        widget.onDateSelected(date);
      },
    );
  }

  String _getDisplayText() {
    if (widget.controller?.text.isNotEmpty ?? false) {
      return widget.controller!.text;
    } else if (selectedDate == null) {
      return 'date_format'.tr();
    } else {
      String lang = dataLang();
      String formattedDate;

      if (lang == 'ru') {
        formattedDate = DateFormat('d MMMM y', 'ru_RU').format(selectedDate!);
      } else if (lang == 'uz') {
        formattedDate = DateFormat('d MMMM y', 'uz_UZ').format(selectedDate!);
      } else {
        formattedDate = DateFormat('d MMMM y').format(selectedDate!);
      }

      return formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: context.inputColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.isDarkMode
                ? ProjectTheme.borderDark
                : ProjectTheme.borderLight,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getDisplayText(),
                style: context.textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.calendar_month,
              color: context.isDarkMode
                  ? ProjectTheme.secondaryTextDark
                  : ProjectTheme.secondaryTextLight,
            ),
          ],
        ),
      ),
    );
  }
}
