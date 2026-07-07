part of 'pop_destinations_cubit.dart';

abstract class PopularDestinationState {}

class PopularDestinationInitState extends PopularDestinationState {}

class PopularDestinationLoadingState extends PopularDestinationState {}

class PopularDestinationSuccessState extends PopularDestinationState {
  List<PopDestinationsModel> destinations;
  PopularDestinationSuccessState(this.destinations);
}
