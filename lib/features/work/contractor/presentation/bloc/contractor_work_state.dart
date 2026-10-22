part of 'contractor_work_bloc.dart';

sealed class ContractorWorkState {
  const ContractorWorkState();
}

final class ContractorWorkInitial extends ContractorWorkState {
  const ContractorWorkInitial();
}

final class ContractorWorkLoadInProgress extends ContractorWorkState {
  const ContractorWorkLoadInProgress();
}

final class ContractorWorkLoadSuccess extends ContractorWorkState {
  const ContractorWorkLoadSuccess({
    required this.overview,
    this.selectedTabIndex = 0,
    this.selectedContractFilterIndex = 0,
    this.filter = const ContractorWorkFilter(),
  });

  final ContractorWorkOverview overview;
  final int selectedTabIndex;
  final int selectedContractFilterIndex;
  final ContractorWorkFilter filter;

  List<ContractorContractProject> get filteredContracts =>
      selectedContractFilterIndex == 0
      ? overview.inProgressContracts
      : overview.completedContracts;
}

final class ContractorWorkLoadFailure extends ContractorWorkState {
  const ContractorWorkLoadFailure(this.failure);

  final Failure failure;
}
