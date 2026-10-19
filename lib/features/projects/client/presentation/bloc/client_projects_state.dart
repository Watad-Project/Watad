part of 'client_projects_bloc.dart';

enum ClientProjectsStatus { initial, loading, success, failure }

final class ClientProjectsState {
  const ClientProjectsState({
    this.status = ClientProjectsStatus.initial,
    this.projects = const [],
    this.failure,
  });

  final ClientProjectsStatus status;

  /// Newest first.
  final List<ClientProject> projects;
  final Failure? failure;
}
