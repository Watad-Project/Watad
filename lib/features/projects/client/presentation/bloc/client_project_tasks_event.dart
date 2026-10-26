part of 'client_project_tasks_bloc.dart';

sealed class ClientProjectTasksEvent {
  const ClientProjectTasksEvent();
}

/// The page opened, the client pulled to refresh or tapped retry, or came
/// back from one of the project's screens.
final class ClientProjectTasksFetched extends ClientProjectTasksEvent {
  const ClientProjectTasksFetched(this.projectId);

  final String projectId;
}
