part of 'top_city_cubit.dart';

abstract class TopCityState extends Equatable {
  const TopCityState();

  @override
  List<Object?> get props => [];
}

class TopCityInitState extends TopCityState {
  const TopCityInitState();
}

class TopCityLoadingState extends TopCityState {
  const TopCityLoadingState();
}

class TopCitySuccessState extends TopCityState {
  final List<TopCityModel> topCities;
  const TopCitySuccessState(this.topCities);

  @override
  List<Object?> get props => [topCities];
}
