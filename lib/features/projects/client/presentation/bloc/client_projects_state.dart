part of 'client_projects_bloc.dart';

sealed class ClientProjectsState {
  const ClientProjectsState();
}

final class ClientProjectsInitial extends ClientProjectsState {
  const ClientProjectsInitial();
}

final class ClientProjectsLoadInProgress extends ClientProjectsState {
  const ClientProjectsLoadInProgress();
}

final class ClientProjectsLoadSuccess extends ClientProjectsState {
  const ClientProjectsLoadSuccess(this.projects);

  final List<ClientProject> projects;
}

final class ClientProjectsLoadFailure extends ClientProjectsState {
  const ClientProjectsLoadFailure(this.failure);

  final Failure failure;
}
