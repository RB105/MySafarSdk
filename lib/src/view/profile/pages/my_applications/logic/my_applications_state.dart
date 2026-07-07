part of 'my_applications_cubit.dart';

abstract class MyApplicationsState {}

class MyApplicationsInitState extends MyApplicationsState {}

class MyApplicationsLoadingState extends MyApplicationsState {}

class MyApplicationsSuccessState extends MyApplicationsState {
  final List<MyApplicationModel> applications;
  MyApplicationsSuccessState(this.applications);
}

class MyApplicationsErrorState extends MyApplicationsState {
  final String error;
  MyApplicationsErrorState(this.error);
}
