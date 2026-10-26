part of 'contractor_project_tasks_bloc.dart';

sealed class ContractorProjectTasksEvent {
  const ContractorProjectTasksEvent();
}

/// Dispatched when the schedule screen opens, when the contractor pulls to
/// refresh or taps retry, or when returning from a child screen.
final class ContractorProjectTasksFetched extends ContractorProjectTasksEvent {
  const ContractorProjectTasksFetched(this.projectId);

  final String projectId;
}
