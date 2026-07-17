import 'package:mysafar_sdk/src/core/localization/sdk_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mysafar_sdk/src/core/extension/context_ext.dart';
import 'package:mysafar_sdk/src/core/extension/date_time_ext.dart';
import 'package:mysafar_sdk/src/core/styles/grarient_box_border.dart';
import 'package:mysafar_sdk/src/core/styles/theme.dart';
import 'package:mysafar_sdk/src/cubit/main/datePicker/date_picker_cubit.dart';
import 'package:mysafar_sdk/src/generated/assets.dart';
import 'package:mysafar_sdk/src/model/remote/avia/airports_model.dart'
    show AirPortsModel;
import 'package:mysafar_sdk/src/model/remote/avia/ticket_date_price_model.dart'
    show TicketDatePriceModel;
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class DateCalendarWidget extends StatefulWidget {
  final int type;
  final PickerDateRange? params;
  final AirPortsModel? fromDir;
  final AirPortsModel? toDir;

  const DateCalendarWidget(
      {super.key,
      required this.type,
      required this.params,
      this.fromDir,
      this.toDir});

  @override
  State<DateCalendarWidget> createState() => _DateCalendarWidgetState();
}

class _DateCalendarWidgetState extends State<DateCalendarWidget> {
  final datePickerController = DateRangePickerController();
  PickerDateRange? pickerDateRange;
  DateTime? selectedDate;

  TicketDatePriceModel datePrices = TicketDatePriceModel();

  /// Memoized price lookup keyed by the normalized (y/m/d) date so the
  /// cellBuilder does not scan the whole price list for every cell on each
  /// rebuild.
  Map<DateTime, String> _priceByDate = {};

  void _rebuildPriceMap() {
    final map = <DateTime, String>{};
    for (final element in datePrices.uzsPrices ?? []) {
      final date = element.date;
      if (date != null && element.sum != "0") {
        map[DateTime(date.year, date.month, date.day)] = element.sum ?? "";
      }
    }
    _priceByDate = map;
  }

  @override
  void initState() {
    if (widget.type == 1) {
      pickerDateRange = widget.params;
      datePickerController.selectedRange = pickerDateRange;
    } else {
      pickerDateRange = PickerDateRange(widget.params?.startDate, null);
      selectedDate = widget.params?.startDate;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DatePickerCubit(
          fromWhere: widget.fromDir,
          toWhere: widget.toDir,
          flightType: widget.type),
      child: BlocConsumer<DatePickerCubit, DatePickerState>(
        listener: (context, state) {
          if (state is DatePickerFilledState) {
            setState(() {
              datePrices = state.datePrice;
              _rebuildPriceMap();
            });
          }
        },
        builder: (context, state) => Scaffold(
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: context.k16horizontalPadding,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(pickerDateRange),
                  style: ProjectTheme.blueButtonStyle,
                  child: Text(
                    "done".tr(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  )),
            ),
          ),
          appBar: AppBar(
            leading: SizedBox.fromSize(),
            leadingWidth: 0,
            centerTitle: false,
            titleSpacing: 16,
            title: Text(
              "date_calendar_title".tr(),
              style: context.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Material(
                  color: ProjectTheme.borderLight.withAlpha(120),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: context.k16horizontalPadding,
            child: Column(
              children: [
                context.szBoxHeight16,
                _getDateLabel(),
                context.szBoxHeight16,
                Expanded(
                  child: SfDateRangePicker(
                    controller: datePickerController,
                    enableMultiView: true,
                    todayHighlightColor: Colors.transparent,
                    rangeSelectionColor: Colors.transparent,
                    selectionColor: Colors.transparent,
                    endRangeSelectionColor: Colors.transparent,
                    startRangeSelectionColor: Colors.transparent,
                    backgroundColor: context.theme.scaffoldBackgroundColor,
                    allowViewNavigation: false,
                    enablePastDates: false,
                    selectionShape: DateRangePickerSelectionShape.rectangle,
                    viewSpacing: 0,
                    headerStyle: DateRangePickerHeaderStyle(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      textStyle: TextStyle(
                        fontFamily: "Gilroy",
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: context.textTheme.bodyMedium?.color,
                      ),
                    ),
                    navigationDirection:
                        DateRangePickerNavigationDirection.vertical,
                    onSelectionChanged: (v) {
                      HapticFeedback.mediumImpact();
                      if (v.value.runtimeType == PickerDateRange) {
                        setState(() {
                          final start = (v.value as PickerDateRange).startDate;
                          final end = (v.value as PickerDateRange).endDate;
                          
                        if (pickerDateRange?.startDate != null &&
                              pickerDateRange?.endDate == null &&
                              start?.isSame(pickerDateRange!.startDate!) == true &&
                              end == null) {
                            pickerDateRange = PickerDateRange(start, start);
                            datePickerController.selectedRange = pickerDateRange;
                            return;
                          }
                          
                          if (end?.isSame(start) ?? false) {
                            if (pickerDateRange?.endDate == null) {
                              pickerDateRange = PickerDateRange(start, start);
                              datePickerController.selectedRange = pickerDateRange;
                              return;
                            }
                            pickerDateRange = PickerDateRange(start, null);
                            return;
                          }
                          pickerDateRange = v.value as PickerDateRange;
                        });
                      } else if (v.value.runtimeType == DateTime) {
                        setState(() {
                          selectedDate = v.value;
                          pickerDateRange = PickerDateRange(selectedDate, null);
                        });
                      }
                    },
                    extendableRangeSelectionDirection:
                        ExtendableRangeSelectionDirection.forward,
                    navigationMode: DateRangePickerNavigationMode.scroll,
                    initialDisplayDate: DateTime.now(),
                    monthViewSettings: DateRangePickerMonthViewSettings(
                        viewHeaderHeight: 36,
                        viewHeaderStyle: DateRangePickerViewHeaderStyle(
                          textStyle: TextStyle(
                            fontFamily: "Gilroy",
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.textTheme.headlineSmall?.color,
                          ),
                        )),
                    view: DateRangePickerView.month,
                    minDate: DateTime.now(),
                    cellBuilder: (context, details) {
                      final cellDate = details.date;
                      final price = _priceByDate[DateTime(
                              cellDate.year, cellDate.month, cellDate.day)] ??
                          "";
                      final date = details.date;
                      final isBefore = details.date.isBefore(DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day));

                      if (widget.type != 1) {
                        final isSelected = selectedDate != null
                            ? details.date.isSame(selectedDate!)
                            : false;
                        return _getCellContainer(
                            date, isBefore, isSelected, false, price);
                      }
                      final isInRange = pickerDateRange != null &&
                          pickerDateRange?.startDate != null &&
                          pickerDateRange?.endDate != null &&
                          date.isAfter(pickerDateRange!.startDate!) &&
                          date.isBefore(pickerDateRange!.endDate!);

                      final isStart =
                          pickerDateRange?.startDate?.isSame(details.date) ??
                              false;

                      final isEnd =
                          pickerDateRange?.endDate?.isSame(details.date) ??
                              false;

                      return _getCellContainer(details.date, isBefore,
                          isStart || isEnd, isInRange, price);
                    },
                    selectionMode: widget.type == 0 || widget.type == 2
                        ? DateRangePickerSelectionMode.single
                        : DateRangePickerSelectionMode.range,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getDateLabel() {
    if (widget.type == 0) {
      return SizedBox(
        height: 48,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: getBorderColor(true)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Visibility(
                  visible: pickerDateRange != null &&
                      pickerDateRange?.startDate != null,
                  replacement: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "depDate".tr(),
                        style: context.textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: context.k12horizontalPadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "depDate".tr(),
                              style: context.textTheme.headlineSmall,
                            ),
                            Text(
                              pickerDateRange != null &&
                                      pickerDateRange?.startDate != null
                                  ? pickerDateRange!.startDate!.dateWithMonth
                                  : "",
                              style: context.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: InkWell(
                            onTap: () => setState(() {
                              pickerDateRange = PickerDateRange(
                                  null, pickerDateRange?.endDate);
                            }),
                            child:
                                SvgPicture.asset(
                                    Assets.iconsCircleXmarkIcon),
                          ),
                        )
                      ],
                    ),
                  ))
            ],
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: getBorderColor(true)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Visibility(
                      visible: pickerDateRange != null &&
                          pickerDateRange?.startDate != null,
                      replacement: Center(
                        child: Text(
                          "depDate".tr(),
                          style: context.textTheme.headlineMedium,
                        ),
                      ),
                      child: Padding(
                        padding: context.k12horizontalPadding,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "depDate".tr(),
                                  style: context.textTheme.headlineSmall,
                                ),
                                Text(
                                  pickerDateRange != null &&
                                          pickerDateRange?.startDate != null
                                      ? pickerDateRange!
                                          .startDate!.dateWithMonth
                                      : "",
                                  style: context.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: InkWell(
                                onTap: () => setState(() {
                                  pickerDateRange = PickerDateRange(
                                      null, pickerDateRange?.endDate);
                                }),
                                child: SvgPicture.asset(
                                    Assets.iconsCircleXmarkIcon),
                              ),
                            )
                          ],
                        ),
                      ))
                ],
              ),
            ),
          ),
        ),
        context.szBoxWidth12,
        Expanded(
          child: SizedBox(
            height: 48,
            child: Visibility(
              visible: widget.type == 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: getBorderColor(false)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Visibility(
                        visible: pickerDateRange != null &&
                            pickerDateRange?.endDate != null,
                        replacement: Center(
                          child: Text(
                            "arrDate".tr(),
                            style: context.textTheme.headlineMedium,
                          ),
                        ),
                        child: Padding(
                          padding: context.k12horizontalPadding,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "return".tr(),
                                    style: context.textTheme.headlineSmall,
                                  ),
                                  Text(
                                    pickerDateRange != null &&
                                            pickerDateRange?.endDate != null
                                        ? pickerDateRange!
                                            .endDate!.dateWithMonth
                                        : "",
                                    style: context.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: InkWell(
                                  onTap: () => setState(() {
                                    pickerDateRange = PickerDateRange(
                                        pickerDateRange?.startDate, null);
                                  }),
                                  child: SvgPicture.asset(
                                      Assets.iconsCircleXmarkIcon),
                                ),
                              )
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Container _getCellContainer(DateTime date, bool isBefore, bool isSelected,
      bool isInRange, String price) {
    return Container(
      width: 44,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Container(
                decoration: BoxDecoration(
                  color: getCellBgColor(isSelected, isInRange, isBefore),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Center(
                  child: Text(
                    "${date.day}",
                    style: getDateTextStyle(isBefore, isSelected),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
              flex: 4,
              child: Text(
                price,
                style: TextStyle(fontSize: 12.0, color: ProjectTheme.success),
              ))
        ],
      ),
    );
  }

  Color getCellBgColor(bool isSelected, bool isInRange, bool isBefore) {
    if (isSelected) {
      return ProjectTheme.brandColor;
    } else if (isInRange) {
      // Oraliq (between) kunlar — tanlangan kunlar bilan uyg'un bo'lishi uchun
      // brand ko'kning och tusi. Avvalgi `disabledBgColor` light temada
      // "o'chirilgan" kulrang bo'lib, noto'g'ri ko'rinardi.
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      return ProjectTheme.brandColor.withAlpha(isDark ? 70 : 28);
    } else {
      return Colors.transparent;
    }
  }

  TextStyle getDateTextStyle(bool isBefore, bool isSelected) {
    if (isBefore) {
      return context.textTheme.headlineSmall?.copyWith(fontSize: 14) ??
          TextStyle();
    }

    if (isSelected) {
      return context.textTheme.bodySmall?.copyWith(
              fontSize: 14, color: Colors.white, fontWeight: FontWeight.w400) ??
          TextStyle();
    }

    return context.textTheme.bodySmall
            ?.copyWith(fontSize: 14, fontWeight: FontWeight.w400) ??
        TextStyle();
  }

  BoxBorder getBorderColor(bool isStartDate) {
    if (widget.type == 1) {
      if (isStartDate) {
        if (pickerDateRange?.startDate == null) {
          return GradientBoxBorder(
              gradient: LinearGradient(colors: ProjectTheme.focusGradient));
        } else {
          return context.boxBorder;
        }
      } else {
        if (pickerDateRange?.startDate != null &&
            pickerDateRange?.endDate == null) {
          return GradientBoxBorder(
              gradient: LinearGradient(colors: ProjectTheme.focusGradient));
        } else {
          return context.boxBorder;
        }
      }
    }
    return GradientBoxBorder(
        gradient: LinearGradient(colors: ProjectTheme.focusGradient));
  }
}
