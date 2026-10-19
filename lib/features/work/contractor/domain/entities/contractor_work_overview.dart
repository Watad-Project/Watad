import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';

/// The contractor's work tab data: open opportunities and assigned contracts.
class ContractorWorkOverview {
  const ContractorWorkOverview({
    required this.openProjects,
    this.contracts = const [],
    int? contractsCount,
  }) : contractsCount = contractsCount ?? contracts.length;

  final List<ContractorOpenProject> openProjects;
  final List<ContractorContractProject> contracts;
  final int contractsCount;

  int get opportunitiesCount => openProjects.length;

  List<ContractorContractProject> get inProgressContracts =>
      contracts.where((c) => c.isInProgress).toList(growable: false);

  List<ContractorContractProject> get completedContracts =>
      contracts.where((c) => c.isCompleted).toList(growable: false);

  int get inProgressContractsCount => inProgressContracts.length;

  int get completedContractsCount => completedContracts.length;
}
