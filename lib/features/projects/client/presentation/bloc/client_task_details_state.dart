part of 'client_task_details_bloc.dart';

enum ClientTaskDetailsStatus { initial, loading, success, failure }

final class ClientTaskDetailsState {
  const ClientTaskDetailsState({
    this.status = ClientTaskDetailsStatus.initial,
    this.project,
    this.task,
    this.failure,
    this.answering,
    this.answered,
    this.errorKey,
  });

  final ClientTaskDetailsStatus status;
  final ClientProject? project;
  final ClientProjectTask? task;

  /// Why the page couldn't load.
  final Failure? failure;

  /// The answer being sent.
  final TaskStatus? answering;

  /// The answer the server took: the page goes back to the timeline.
  final TaskStatus? answered;

  /// Why the answer failed, as a translation key.
  final String? errorKey;

  /// A proposed task is answered while the project is in progress (the
  /// server checks it too).
  bool get canAnswer =>
      task?.status == TaskStatus.proposed &&
      project?.status == ProjectStatus.inProgress;

  ClientTaskDetailsState copyWith({
    ClientTaskDetailsStatus? status,
    ClientProject? project,
    ClientProjectTask? task,
    Failure? Function()? failure,
    TaskStatus? Function()? answering,
    TaskStatus? Function()? answered,
    String? Function()? errorKey,
  }) {
    return ClientTaskDetailsState(
      status: status ?? this.status,
      project: project ?? this.project,
      task: task ?? this.task,
      failure: failure == null ? this.failure : failure(),
      answering: answering == null ? this.answering : answering(),
      answered: answered == null ? this.answered : answered(),
      errorKey: errorKey == null ? this.errorKey : errorKey(),
    );
  }
}
