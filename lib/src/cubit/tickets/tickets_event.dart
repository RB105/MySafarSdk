part of 'tickets_cubit.dart';

sealed class TicketEvent {}

class GetRecommendationsEvent extends TicketEvent {
  final RecommendationRequestBody requestBody;
  GetRecommendationsEvent(this.requestBody);
}

class SendFilterEvent extends TicketEvent {
  final RecommendationRequestBody requestBody;
  SendFilterEvent(this.requestBody);
}

