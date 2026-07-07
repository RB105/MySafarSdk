part of 'users_data_cubit.dart';

abstract class UsersDataState {}

class UsersDataInitState extends UsersDataState {}

class UsersDataLoadingState extends UsersDataState {}


class UsersDataEmptyState extends UsersDataState {}
class UsersDataCreateState extends UsersDataState {}

class UsersDataErrorState extends UsersDataState {
  final ErrorType? errorType;
  final String error;
 UsersDataErrorState({required this.error , this.errorType});
}

class UsersDataSuccessState extends UsersDataState {
  final List<UsersModel> usersModel;
 UsersDataSuccessState(this.usersModel);
}
