part of 'ticketed_booking_search_cubit.dart';

abstract class TicketedBookingSearchState {}

class TicketedBookingSearchInitial extends TicketedBookingSearchState {}

class TicketedBookingSearchLoading extends TicketedBookingSearchState {}

class TicketedBookingSearchSuccess extends TicketedBookingSearchState {
  final ConfirmedTicketsModel ticket;
  TicketedBookingSearchSuccess(this.ticket);
}

class TicketedBookingSearchError extends TicketedBookingSearchState {
  final String error;
  final ErrorType? errorType;
  TicketedBookingSearchError({required this.error, this.errorType});
}
