part of 'destination_detail_cubit.dart';

abstract class DestinationDetailState {}

class DestinationDetailLoadingState extends DestinationDetailState {}

class DestinationDetailSuccessState extends DestinationDetailState {
  final DestinationDetailModel detail;

  DestinationDetailSuccessState(this.detail);
}

class DestinationDetailErrorState extends DestinationDetailState {}

/// CMS shahri v1 bazasida topilmadi — xaritali sahifaga yo'naltirish.
class DestinationDetailRedirectMapState extends DestinationDetailState {}
