part of 'ofd_cheques_cubit.dart';

abstract class OfdChequesState {
  const OfdChequesState();
}

class OfdChequesInitState extends OfdChequesState {
  const OfdChequesInitState();
}

class OfdChequesLoadingState extends OfdChequesState {
  const OfdChequesLoadingState();
}

class OfdChequesEmptyState extends OfdChequesState {
  const OfdChequesEmptyState();
}

class OfdChequesErrorState extends OfdChequesState {
  final String error;
  const OfdChequesErrorState(this.error);
}

class OfdChequesSuccesState extends OfdChequesState {
  final List<ChequeModel> cheques;
  const OfdChequesSuccesState(this.cheques);
}
