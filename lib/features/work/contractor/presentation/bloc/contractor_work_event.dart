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

final class ContractorWorkSearchQueryChanged extends ContractorWorkEvent {
  const ContractorWorkSearchQueryChanged(this.searchQuery);

  final String searchQuery;
}

final class ContractorWorkFilterUpdated extends ContractorWorkEvent {
  const ContractorWorkFilterUpdated(this.filter);

  final ContractorWorkFilter filter;
}

final class ContractorWorkFilterReset extends ContractorWorkEvent {
  const ContractorWorkFilterReset();
}
