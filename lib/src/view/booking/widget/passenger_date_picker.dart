import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';

/// Yo'lovchi uchun sana tanlash dialog
class PassengerDatePicker {
  static void show({
    required BuildContext context,
    required TextEditingController controller,
    required bool isFutureOnly,
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
  }) {
    final today = DateTime.now();
    final todayOnlyDate = DateTime(today.year, today.month, today.day);
    DateTime tempPickedDate = initialDate ?? todayOnlyDate;

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            height: 350,
            decoration: BoxDecoration(
              color: context.color.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel_outlined),
                  ),
                ),

                // Date Picker
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoTheme.of(context).copyWith(
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: context.textTheme.bodyMedium
                            ?.copyWith(fontSize: 20),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      initialDateTime: todayOnlyDate,
                      mode: CupertinoDatePickerMode.date,
                      minimumDate: isFutureOnly ? todayOnlyDate : null,
                      maximumDate: isFutureOnly ? null : todayOnlyDate,
                      onDateTimeChanged: (DateTime newDate) {
                        tempPickedDate = newDate;
                      },
                    ),
                  ),
                ),

                // Tanlash tugmasi
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.text =
                            DateFormat('dd.MM.yyyy').format(tempPickedDate);
                        onDateSelected(tempPickedDate);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: ProjectTheme.brandColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'select'.tr(),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
