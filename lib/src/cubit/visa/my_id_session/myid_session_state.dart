part of 'myid_session_cubit.dart';

abstract class MyIdSessionState {}

class MyIdSessionInitState extends MyIdSessionState {}

class MyIdSessionLoadingState extends MyIdSessionState {}
class MyIdSessionErrorState extends MyIdSessionState {
  String error;
  MyIdSessionErrorState(this.error);
}
class MyIdSessionSuccessState extends MyIdSessionState {
  dynamic data;
  MyIdSessionSuccessState(this.data);
}
