part of 'my_contracts_cubit.dart';

abstract class MyContractsState {}

class MyContractsInitState extends MyContractsState {}

class MyContractsLoadingState extends MyContractsState {}

class MyContractsSuccessState extends MyContractsState {
  final List<MyContractModel> contracts;
  MyContractsSuccessState(this.contracts);
}

class MyContractsErrorState extends MyContractsState {
  final String error;
  MyContractsErrorState(this.error);
}