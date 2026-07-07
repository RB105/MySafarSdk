part of 'uz_ban_check_cubit.dart';

abstract class UzBanCheckState {}

class UzBanCheckInitState extends UzBanCheckState {}

class UzBanCheckLoadingState extends UzBanCheckState {}

class UzBanCheckSuccessState extends UzBanCheckState {
  dynamic data;
  UzBanCheckSuccessState(this.data);
}
