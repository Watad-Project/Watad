part of 'contractor_task_update_bloc.dart';

enum ContractorTaskUpdateStatus { initial, loading, success, failure }

final class ContractorTaskUpdateState {
  const ContractorTaskUpdateState({
    this.status = ContractorTaskUpdateStatus.initial,
    this.project,
    this.tasks = const [],
    this.failure,
    this.isSubmitting = false,
    this.submittedUpdateId,
    this.submissionFailure,
  });

  final ContractorTaskUpdateStatus status;
  final ContractorTaskProject? project;

  /// Tasks open for a new progress update (`canSendUpdate == true`).
  final List<ContractorProjectTask> tasks;
  final Failure? failure;

  final bool isSubmitting;
  final String? submittedUpdateId;
  final Failure? submissionFailure;

  ContractorTaskUpdateState copyWith({
    ContractorTaskUpdateStatus? status,
    ContractorTaskProject? project,
    List<ContractorProjectTask>? tasks,
    Failure? failure,
    bool clearFailure = false,
    bool? isSubmitting,
    String? submittedUpdateId,
    bool clearSubmittedUpdateId = false,
    Failure? submissionFailure,
    bool clearSubmissionFailure = false,
  }) {
    return ContractorTaskUpdateState(
      status: status ?? this.status,
      project: project ?? this.project,
      tasks: tasks ?? this.tasks,
      failure: clearFailure ? null : (failure ?? this.failure),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedUpdateId: clearSubmittedUpdateId
          ? null
          : (submittedUpdateId ?? this.submittedUpdateId),
      submissionFailure: clearSubmissionFailure
          ? null
          : (submissionFailure ?? this.submissionFailure),
    );
  }
}
