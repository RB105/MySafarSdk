part of 'confirmed_tickets_cubit.dart';

abstract class ConfirmedTicketsState {}

class ConfirmedTicketsInitState extends ConfirmedTicketsState {}

class ConfirmedTicketsLoadingState extends ConfirmedTicketsState {}


class ConfirmedTicketsEmptyState extends ConfirmedTicketsState {}

class ConfirmedTicketsErrorState extends ConfirmedTicketsState {
  final ErrorType? errorType;
  final String error;
  ConfirmedTicketsErrorState({required this.error , this.errorType});
}

class ConfirmedTicketsSuccessState extends ConfirmedTicketsState {
  final List<ConfirmedTicketsModel> confirmedTickets;
  ConfirmedTicketsSuccessState(this.confirmedTickets);
}
