part of 'city_choose_cubit.dart';

/// this is for [avia_airports] api
abstract class CityChooseStates extends Equatable {
  const CityChooseStates();

  @override
  List<Object?> get props => [];
}

class CityChooseInitState extends CityChooseStates {
  final AirPortsModel? nearbyAirport;
  final bool isLoadingNearby;

  const CityChooseInitState({this.nearbyAirport, this.isLoadingNearby = false});

  @override
  List<Object?> get props => [nearbyAirport, isLoadingNearby];
}

class CityChooseLoadingState extends CityChooseStates {
  const CityChooseLoadingState();
}

class CityChooseErrorState extends CityChooseStates {
  final String error;
  const CityChooseErrorState(this.error);

  @override
  List<Object?> get props => [error];
}

class CityChooseSuccessState extends CityChooseStates {
  final List<AirPortsModel> airports;
  const CityChooseSuccessState(this.airports);

  @override
  List<Object?> get props => [airports];
}