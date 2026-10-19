part of 'contractor_work_bloc.dart';

sealed class ContractorWorkEvent {
  const ContractorWorkEvent();
}

final class ContractorWorkStarted extends ContractorWorkEvent {
  const ContractorWorkStarted();
}

final class ContractorWorkRefreshed extends ContractorWorkEvent {
  const ContractorWorkRefreshed();
}

final class ContractorWorkTabChanged extends ContractorWorkEvent {
  const ContractorWorkTabChanged(this.tabIndex);

  final int tabIndex;
}

final class ContractorWorkContractFilterChanged extends ContractorWorkEvent {
  const ContractorWorkContractFilterChanged(this.filterIndex);

  final int filterIndex;
}
