part of 'client_projects_bloc.dart';

enum ClientProjectsStatus { initial, loading, success, failure }

final class ClientProjectsState {
  const ClientProjectsState({
    this.status = ClientProjectsStatus.initial,
    this.projects = const [],
    this.failure,
    this.filter = ClientProjectsFilter.waiting,
  });

  final ClientProjectsStatus status;

  /// Newest first.
  final List<ClientProject> projects;
  final Failure? failure;

  /// The selected chip. A new project waits for approval or offers, so the
  /// list opens there.
  final ClientProjectsFilter filter;

  /// The projects of the selected chip, newest first.
  List<ClientProject> get visibleProjects =>
      projects.where(filter.matches).toList();
}
