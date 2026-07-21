import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/core/tools/formatters.dart'
    show ElementFormatter;

/// Yo'lovchi uchun sana tanlash bottom sheet (MySafar booking uslubida).
class PassengerDatePicker {
  static void show({
    required BuildContext context,
    required TextEditingController controller,
    required bool isFutureOnly,
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
    String? title,
  }) {
    final today = DateTime.now();
    final todayOnlyDate = DateTime(today.year, today.month, today.day);
    final initial = _resolveInitial(
      controller: controller,
      isFutureOnly: isFutureOnly,
      initialDate: initialDate,
      todayOnlyDate: todayOnlyDate,
    );
    DateTime tempPickedDate = initial;

    // showCupertinoModalPopup MaterialApp temasini olmaydi — ranglarni
    // chaqiruvchi context'dan oldindan olamiz.
    final isDark = context.isDarkMode;
    final sheetColor =
        isDark ? ProjectTheme.cardColorDark : ProjectTheme.cardColorLight;
    final materialTheme = isDark ? ProjectTheme.dark : ProjectTheme.light;

    showCupertinoModalPopup(
      context: context,
      builder: (sheetContext) {
        final titleColor = isDark
            ? ProjectTheme.textColorDark
            : ProjectTheme.textColorLight;

        return Theme(
          data: materialTheme,
          child: CupertinoTheme(
            data: _cupertinoTheme(isDark: isDark, sheetColor: sheetColor),
            child: SafeArea(
              top: false,
              child: Material(
                color: sheetColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (isDark
                                ? ProjectTheme.borderDark
                                : ProjectTheme.borderLight)
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title ?? 'birth_date'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'packages/mysafar_sdk/Gilroy',
                                color: titleColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: Icon(
                              Icons.close_rounded,
                              color: isDark
                                  ? ProjectTheme.secondaryTextDark
                                  : ProjectTheme.secondaryTextLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ColoredBox(
                      color: sheetColor,
                      child: SizedBox(
                        height: 216,
                        width: double.infinity,
                        child: _SdkDateWheelPicker(
                          isDark: isDark,
                          sheetColor: sheetColor,
                          initial: initial,
                          minimumDate: isFutureOnly ? todayOnlyDate : null,
                          maximumDate: isFutureOnly ? null : todayOnlyDate,
                          onChanged: (date) => tempPickedDate = date,
                        ),
                      ),
                    ),
                    ColoredBox(
                      color: sheetColor,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: ProjectTheme.brandColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              controller.text = DateFormat('dd.MM.yyyy')
                                  .format(tempPickedDate);
                              onDateSelected(tempPickedDate);
                              Navigator.pop(sheetContext);
                            },
                            child: Text(
                              'select'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'packages/mysafar_sdk/Gilroy',
                              ),
                            ),
                          ),
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
    );
  }

  static CupertinoThemeData _cupertinoTheme({
    required bool isDark,
    required Color sheetColor,
  }) {
    final textStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      fontFamily: 'packages/mysafar_sdk/Gilroy',
      color: isDark ? ProjectTheme.textColorDark : ProjectTheme.textColorLight,
    );

    return CupertinoThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: ProjectTheme.brandColor,
      scaffoldBackgroundColor: sheetColor,
      barBackgroundColor: sheetColor,
      textTheme: CupertinoTextThemeData(
        textStyle: textStyle,
        pickerTextStyle: textStyle,
        dateTimePickerTextStyle: textStyle,
      ),
    );
  }

  /// Maydondagi `dd.MM.yyyy` qiymatidan boshlanadi; bo'sh/noto'g'ri bo'lsa
  /// standart boshlang'ich (tug'ilgan sana: 1990, pasport muddati: bugun).
  static DateTime _resolveInitial({
    required TextEditingController controller,
    required bool isFutureOnly,
    required DateTime todayOnlyDate,
    DateTime? initialDate,
  }) {
    DateTime initial = isFutureOnly
        ? todayOnlyDate
        : (initialDate ?? DateTime(1990, 1, 1));

    try {
      final parsed =
          DateFormat('dd.MM.yyyy').parseStrict(controller.text.trim());
      if (isFutureOnly) {
        initial = parsed.isBefore(todayOnlyDate) ? todayOnlyDate : parsed;
      } else {
        initial = parsed.isAfter(todayOnlyDate) ? todayOnlyDate : parsed;
      }
    } catch (_) {
      // Maydon bo'sh yoki noto'g'ri formatda — standart boshlang'ich qoladi.
    }

    return initial;
  }
}

/// SDK tarjimalaridagi oy nomlari bilan g'ildirakli sana tanlagich.
class _SdkDateWheelPicker extends StatefulWidget {
  final bool isDark;
  final Color sheetColor;
  final DateTime initial;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final ValueChanged<DateTime> onChanged;

  const _SdkDateWheelPicker({
    required this.isDark,
    required this.sheetColor,
    required this.initial,
    required this.onChanged,
    this.minimumDate,
    this.maximumDate,
  });

  @override
  State<_SdkDateWheelPicker> createState() => _SdkDateWheelPickerState();
}

class _SdkDateWheelPickerState extends State<_SdkDateWheelPicker> {
  static const int _minBirthYear = 1920;

  late int _day;
  late int _month;
  late int _year;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  int get _minYear => widget.minimumDate?.year ?? _minBirthYear;

  int get _maxYear => widget.maximumDate?.year ?? DateTime.now().year + 20;

  @override
  void initState() {
    super.initState();
    final clamped = _clampDate(widget.initial);
    _day = clamped.day;
    _month = clamped.month;
    _year = clamped.year;

    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController =
        FixedExtentScrollController(initialItem: _year - _minYear);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  DateTime _clampDate(DateTime date) {
    var d = DateTime(date.year, date.month, date.day);
    if (widget.minimumDate != null && d.isBefore(widget.minimumDate!)) {
      d = widget.minimumDate!;
    }
    if (widget.maximumDate != null && d.isAfter(widget.maximumDate!)) {
      d = widget.maximumDate!;
    }
    final maxDay = _daysInMonth(d.year, d.month);
    if (d.day > maxDay) d = DateTime(d.year, d.month, maxDay);
    return d;
  }

  void _notify() {
    final clamped = _clampDate(DateTime(_year, _month, _day));
    if (clamped.day != _day ||
        clamped.month != _month ||
        clamped.year != _year) {
      setState(() {
        _day = clamped.day;
        _month = clamped.month;
        _year = clamped.year;
      });
      _dayController.jumpToItem(_day - 1);
      _monthController.jumpToItem(_month - 1);
      _yearController.jumpToItem(_year - _minYear);
    }
    widget.onChanged(clamped);
  }

  void _syncDayAfterMonthYearChange() {
    final maxDay = _daysInMonth(_year, _month);
    if (_day > maxDay) {
      _day = maxDay;
      _dayController.jumpToItem(_day - 1);
    }
    _notify();
  }

  TextStyle get _textStyle => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        fontFamily: 'packages/mysafar_sdk/Gilroy',
        color: widget.isDark
            ? ProjectTheme.textColorDark
            : ProjectTheme.textColorLight,
      );

  Widget get _selectionOverlay => CupertinoPickerDefaultSelectionOverlay(
        background: widget.isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.06),
      );

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(_year, _month);
    final years = List.generate(_maxYear - _minYear + 1, (i) => _minYear + i);

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: CupertinoPicker(
            scrollController: _monthController,
            itemExtent: 36,
            backgroundColor: widget.sheetColor,
            selectionOverlay: _selectionOverlay,
            onSelectedItemChanged: (index) {
              setState(() {
                _month = index + 1;
                _syncDayAfterMonthYearChange();
              });
            },
            children: [
              for (int m = 1; m <= 12; m++)
                Center(
                  child: Text(
                    ElementFormatter.formatMonth(m).toLowerCase(),
                    style: _textStyle,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: CupertinoPicker(
            key: ValueKey('$_year-$daysInMonth'),
            scrollController: _dayController,
            itemExtent: 36,
            backgroundColor: widget.sheetColor,
            selectionOverlay: _selectionOverlay,
            onSelectedItemChanged: (index) {
              setState(() {
                _day = index + 1;
                _notify();
              });
            },
            children: [
              for (int d = 1; d <= daysInMonth; d++)
                Center(child: Text('$d', style: _textStyle)),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: CupertinoPicker(
            scrollController: _yearController,
            itemExtent: 36,
            backgroundColor: widget.sheetColor,
            selectionOverlay: _selectionOverlay,
            onSelectedItemChanged: (index) {
              setState(() {
                _year = years[index];
                _syncDayAfterMonthYearChange();
              });
            },
            children: [
              for (final y in years)
                Center(child: Text('$y', style: _textStyle)),
            ],
          ),
        ),
      ],
    );
  }
}
