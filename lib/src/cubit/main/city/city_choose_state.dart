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

  /// Foydalanuvchi "Joriy joylashuv"ni bosdi, lekin aeroport aniqlanmadi.
  final bool locationFailed;

  /// "Tavsiya etilgan joylar" — lokal qidiruvdan tilga mos to'ldirilgan.
  final List<AirPortsModel> suggestions;

  const CityChooseInitState({
    this.nearbyAirport,
    this.isLoadingNearby = false,
    this.locationFailed = false,
    this.suggestions = const [],
  });

  @override
  List<Object?> get props =>
      [nearbyAirport, isLoadingNearby, locationFailed, suggestions];
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

  /// Davlat bo'yicha ochilgan ro'yxat bo'lsa — o'sha davlat kodi/nomi.
  final String? country;

  const CityChooseSuccessState(this.airports, {this.country});

  @override
  List<Object?> get props => [airports, country];
}
