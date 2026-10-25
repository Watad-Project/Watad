part of 'client_project_tasks_bloc.dart';

enum ClientProjectTasksStatus { initial, loading, success, failure }

final class ClientProjectTasksState {
  const ClientProjectTasksState({
    this.status = ClientProjectTasksStatus.initial,
    this.project,
    this.tasks = const [],
    this.failure,
  });

  final ClientProjectTasksStatus status;
  final ClientProject? project;

  /// In timeline order: by start date, then by when they were added.
  final List<ClientProjectTask> tasks;

  /// Why the page couldn't load.
  final Failure? failure;

  /// The contractor is paid while the project is in progress, and after
  /// it's completed (the server takes bank transfers for both).
  bool get canPay => switch (project?.status) {
    ProjectStatus.inProgress || ProjectStatus.completed => true,
    _ => false,
  };

  ClientProjectTasksState copyWith({
    ClientProjectTasksStatus? status,
    ClientProject? project,
    List<ClientProjectTask>? tasks,
    Failure? Function()? failure,
  }) {
    return ClientProjectTasksState(
      status: status ?? this.status,
      project: project ?? this.project,
      tasks: tasks ?? this.tasks,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
