part of 'ticket_tariff_cubit.dart';

abstract class TicketTariffState {}

class TicketTariffInitState extends TicketTariffState {}

class TicketTariffLoadingState extends TicketTariffState {}

class TicketTariffSuccessState extends TicketTariffState {
  final List<FlightTariffModel> tariffs;

  TicketTariffSuccessState(this.tariffs);
}

/// API error yoki bo'sh tariflar ro'yxati.
class TicketTariffUnavailableState extends TicketTariffState {}
