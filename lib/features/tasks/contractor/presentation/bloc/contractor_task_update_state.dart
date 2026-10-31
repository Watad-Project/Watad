part of 'contractor_task_update_bloc.dart';

enum ContractorTaskUpdateStatus { initial, loading, success, failure }

final class ContractorTaskUpdateState {
  const ContractorTaskUpdateState({
    this.status = ContractorTaskUpdateStatus.initial,
    this.project,
    this.tasks = const [],
    this.failure,
  });

  final ContractorTaskUpdateStatus status;
  final ContractorTaskProject? project;

  /// Tasks open for a new progress update (`canSendUpdate == true`).
  final List<ContractorProjectTask> tasks;
  final Failure? failure;

  ContractorTaskUpdateState copyWith({
    ContractorTaskUpdateStatus? status,
    ContractorTaskProject? project,
    List<ContractorProjectTask>? tasks,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ContractorTaskUpdateState(
      status: status ?? this.status,
      project: project ?? this.project,
      tasks: tasks ?? this.tasks,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
