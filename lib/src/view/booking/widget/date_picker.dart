import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/tools/lang_helper.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';

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
    DateTime tempPickedDate =
        selectedDate ?? widget.initialDate ?? DateTime.now();
        final today = DateTime.now();
final todayOnlyDate = DateTime(today.year, today.month, today.day);
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return SafeArea(
            child: Container(
          height: 350,
          decoration: BoxDecoration(
              color: context.color.primaryContainer,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Column(
            children: [
              Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel_outlined))),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoTheme.of(context).copyWith(
                    textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: context.textTheme.bodyMedium
                            ?.copyWith(fontSize: 20)),
                  ),
                  child: CupertinoDatePicker(
                    initialDateTime: todayOnlyDate,
                    mode: CupertinoDatePickerMode.date,
                    minimumDate: widget.isFutureOnly ? todayOnlyDate : null,
                    maximumDate: widget.isFutureOnly ? null : todayOnlyDate,
                    onDateTimeChanged: (DateTime newDate) {
                      tempPickedDate = newDate;
                    },
                  ),
                ),
              ),
              // Select button at bottom
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedDate = tempPickedDate;
                      if (widget.controller != null) {
                        widget.controller!.text =
                            DateFormat('dd.MM.yyyy').format(selectedDate!);
                      }
                    });
                    widget.onDateSelected(selectedDate!);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      backgroundColor: ProjectTheme.brandColor,
                      foregroundColor: Colors.white),
                  child: Text('select'.tr(),
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ));
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

      List<String> dateParts = formattedDate.split(' ');
      dateParts[1] = dateParts[1][0].toUpperCase() + dateParts[1].substring(1);
      return dateParts.join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelectedDate = widget.controller?.text.isNotEmpty ?? false;

    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: context.color.outline, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: hasSelectedDate
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title.tr(),
                    style: context.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w400),
                  ),
                  Text(
                    _getDisplayText(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.title.tr(),
                  style: context.textTheme.headlineSmall
                      ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
      ),
    );
  }
}
