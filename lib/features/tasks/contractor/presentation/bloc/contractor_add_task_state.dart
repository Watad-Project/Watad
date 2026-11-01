part of 'contractor_add_task_bloc.dart';

enum ContractorAddTaskStatus { initial, loading, ready, failure }

final class ContractorAddTaskState {
  const ContractorAddTaskState({
    this.status = ContractorAddTaskStatus.initial,
    this.project,
    this.tasks = const [],
    this.startDate,
    this.titleErrorKey,
    this.descriptionErrorKey,
    this.amountErrorKey,
    this.loadFailure,
    this.submissionFailure,
    this.isSubmitting = false,
    this.isSubmitted = false,
  });

  final ContractorAddTaskStatus status;
  final ContractorTaskProject? project;
  final List<ContractorProjectTask> tasks;
  final DateTime? startDate;
  final String? titleErrorKey;
  final String? descriptionErrorKey;
  final String? amountErrorKey;
  final Failure? loadFailure;
  final Failure? submissionFailure;
  final bool isSubmitting;
  final bool isSubmitted;

  /// Remaining contract budget that can be assigned to tasks (`null` when the
  /// contract has no `agreedAmount`).
  Money? get amountLeft => project?.remainingBudget(tasks);

  ContractorAddTaskState copyWith({
    ContractorAddTaskStatus? status,
    ContractorTaskProject? project,
    List<ContractorProjectTask>? tasks,
    DateTime? Function()? startDate,
    String? Function()? titleErrorKey,
    String? Function()? descriptionErrorKey,
    String? Function()? amountErrorKey,
    Failure? Function()? loadFailure,
    Failure? Function()? submissionFailure,
    bool? isSubmitting,
    bool? isSubmitted,
  }) {
    return ContractorAddTaskState(
      status: status ?? this.status,
      project: project ?? this.project,
      tasks: tasks ?? this.tasks,
      startDate: startDate == null ? this.startDate : startDate(),
      titleErrorKey: titleErrorKey == null
          ? this.titleErrorKey
          : titleErrorKey(),
      descriptionErrorKey: descriptionErrorKey == null
          ? this.descriptionErrorKey
          : descriptionErrorKey(),
      amountErrorKey: amountErrorKey == null
          ? this.amountErrorKey
          : amountErrorKey(),
      loadFailure: loadFailure == null ? this.loadFailure : loadFailure(),
      submissionFailure: submissionFailure == null
          ? this.submissionFailure
          : submissionFailure(),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}
