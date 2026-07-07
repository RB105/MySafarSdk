part of 'popular_destination_info_cubit.dart';


abstract class PopularDestinationInfoState {}

class PopularDestinationInfoInitState extends PopularDestinationInfoState {}

class PopularDestinationInfoLoadingState extends PopularDestinationInfoState {}

class PopularDestinationInfoSuccessState extends PopularDestinationInfoState {
DestinationsInfoModel destinations;
  PopularDestinationInfoSuccessState(this.destinations);
}
