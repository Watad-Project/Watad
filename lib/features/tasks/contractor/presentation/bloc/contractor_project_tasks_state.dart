part of 'contractor_project_tasks_bloc.dart';

enum ContractorProjectTasksStatus { initial, loading, success, failure }

final class ContractorProjectTasksState {
  const ContractorProjectTasksState({
    this.status = ContractorProjectTasksStatus.initial,
    this.project,
    this.tasks = const [],
    this.failure,
  });

  final ContractorProjectTasksStatus status;
  final ContractorTaskProject? project;

  /// Tasks ordered by `start_date` ascending (nulls last), then `created_at`.
  final List<ContractorProjectTask> tasks;
  final Failure? failure;

  /// Only `in_progress` contracts can add or update tasks; `completed`
  /// contracts are read-only.
  bool get canAddTask => project?.isInProgress ?? false;

  /// At least one accepted task without a pending update is needed to send a
  /// progress update.
  bool get canUpdateTask =>
      canAddTask && tasks.any((task) => task.canSendUpdate);

  /// Count of `done` tasks waiting for client approval.
  int get doneCount =>
      tasks.where((task) => task.status == TaskStatus.done).length;

  /// Count of `proposed` tasks waiting for client acceptance.
  int get proposedCount =>
      tasks.where((task) => task.status == TaskStatus.proposed).length;

  /// Whether the summary line above the bottom action bar should be shown.
  bool get hasSummary => doneCount > 0 || proposedCount > 0;

  ContractorProjectTasksState copyWith({
    ContractorProjectTasksStatus? status,
    ContractorTaskProject? project,
    List<ContractorProjectTask>? tasks,
    Failure? Function()? failure,
  }) {
    return ContractorProjectTasksState(
      status: status ?? this.status,
      project: project ?? this.project,
      tasks: tasks ?? this.tasks,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
