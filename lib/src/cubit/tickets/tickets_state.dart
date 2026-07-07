part of 'tickets_cubit.dart';

abstract class TicketsState extends Equatable {
  const TicketsState();

  @override
  List<Object?> get props => [];
}

class TicketLoadingState extends TicketsState {
  const TicketLoadingState();
}

class TicketInitState extends TicketsState {
  const TicketInitState();
}

class TicketEmptyState extends TicketsState {
  const TicketEmptyState();
}

class TicketErrorState extends TicketsState {
  final String errorMsg;
  const TicketErrorState(this.errorMsg);

  @override
  List<Object?> get props => [errorMsg];
}

class TicketSuccessState extends TicketsState {
  final GetRecommendationResModel recommendationRes;

  /// Qolgan manbalardan natija hali kutilmoqda — ro'yxat ostida loading
  /// ko'rsatish uchun.
  final bool isLoadingMore;

  const TicketSuccessState(this.recommendationRes,
      {this.isLoadingMore = false});

  @override
  List<Object?> get props => [recommendationRes, isLoadingMore];
}

class TicketCentrumSuccessState extends TicketsState {
  final GetCentrumRecommendation recommendationRes;
  const TicketCentrumSuccessState(this.recommendationRes);

  @override
  List<Object?> get props => [recommendationRes];
}
