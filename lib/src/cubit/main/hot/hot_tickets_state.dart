part of 'hot_tickets_cubit.dart';

abstract class HotTicketsState extends Equatable {
  const HotTicketsState();

  @override
  List<Object?> get props => [];
}

class HotTicketsInitState extends HotTicketsState {
  const HotTicketsInitState();
}

class HotTicketsLoadingState extends HotTicketsState {
  const HotTicketsLoadingState();
}

class HotTicketsSuccessState extends HotTicketsState {
  final List<HotTicket> flights;
  const HotTicketsSuccessState(this.flights);

  @override
  List<Object?> get props => [flights];
}
