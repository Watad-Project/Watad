part of 'contractor_task_update_bloc.dart';

sealed class ContractorTaskUpdateEvent {
  const ContractorTaskUpdateEvent();
}

final class ContractorTaskUpdateFetched extends ContractorTaskUpdateEvent {
  const ContractorTaskUpdateFetched(this.projectId);

  final String projectId;
}
