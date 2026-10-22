import 'package:watad/features/work/contractor/datasource/models/contractor_contract_project_model.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_open_project_model.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';

class ContractorWorkOverviewModel extends ContractorWorkOverview {
  const ContractorWorkOverviewModel({
    required super.openProjects,
    super.contracts = const [],
    super.contractsCount,
  });

  factory ContractorWorkOverviewModel.fromJson(Map<String, dynamic> json) {
    final openProjectsJson = json['open_projects'] as List<dynamic>? ?? [];
    final contractsJson = json['contracts'] as List<dynamic>? ?? [];
    final tasksJson = json['tasks'] as List<dynamic>? ?? [];

    final tasksByProjectId = <String, List<Map<String, dynamic>>>{};
    for (final rawTask in tasksJson) {
      if (rawTask is! Map) continue;
      final taskMap = Map<String, dynamic>.from(rawTask);
      final projectId = taskMap['project_id'] as String?;
      if (projectId == null || projectId.isEmpty) continue;
      tasksByProjectId.putIfAbsent(projectId, () => []).add(taskMap);
    }

    final contracts = contractsJson
        .whereType<Map<dynamic, dynamic>>()
        .map((row) {
          final contractMap = Map<String, dynamic>.from(row);
          final projectId = contractMap['id'] as String? ?? '';
          if (!contractMap.containsKey('tasks') &&
              tasksByProjectId.containsKey(projectId)) {
            contractMap['tasks'] = tasksByProjectId[projectId];
          }
          return ContractorContractProjectModel.fromJson(contractMap);
        })
        .toList(growable: false);

    final explicitContractsCount = (json['contracts_count'] as num?)?.toInt();

    return ContractorWorkOverviewModel(
      openProjects: openProjectsJson
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (row) => ContractorOpenProjectModel.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(growable: false),
      contracts: contracts,
      contractsCount: explicitContractsCount ?? contracts.length,
    );
  }
}
