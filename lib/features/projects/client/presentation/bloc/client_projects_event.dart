part of 'client_projects_bloc.dart';

sealed class ClientProjectsEvent {
  const ClientProjectsEvent();
}

/// Load the projects: at the start, on pull to refresh, and back from a
/// project's offers.
final class ClientProjectsFetched extends ClientProjectsEvent {
  const ClientProjectsFetched();
}
