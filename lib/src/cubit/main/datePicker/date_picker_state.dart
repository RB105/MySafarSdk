part of 'date_picker_cubit.dart';

abstract class DatePickerState {}

class DatePickerInitState extends DatePickerState {}

class DatePickerFilledState extends DatePickerState {
  final TicketDatePriceModel datePrice;
  DatePickerFilledState(this.datePrice);
}
