part of 'my_contract_detail_cubit.dart';

abstract class MyContractDetailState {}

class MyContractDetailInitState extends MyContractDetailState {}

class MyContractDetailLoadingState extends MyContractDetailState {}

class MyContractDetailSuccessState extends MyContractDetailState {
  final MyContractModel contract;
  MyContractDetailSuccessState(this.contract);
}

class MyContractDetailErrorState extends MyContractDetailState {
  final String error;
  MyContractDetailErrorState(this.error);
}
