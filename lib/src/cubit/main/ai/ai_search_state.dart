part of 'ai_search_cubit.dart';

abstract class AiSearchState extends Equatable {
  const AiSearchState();

  @override
  List<Object?> get props => [];
}

class AiSearchInitState extends AiSearchState {
  const AiSearchInitState();
}

class AiSearchLoadingState extends AiSearchState {
  const AiSearchLoadingState();
}

class AiSearchErrorState extends AiSearchState {
  final String error;
  const AiSearchErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

class AiSearchSuccessState extends AiSearchState {
  final RecommendationRequestBody body;
  const AiSearchSuccessState(this.body);

  @override
  List<Object?> get props => [body];
}
