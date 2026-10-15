part of 'client_projects_bloc.dart';

sealed class ClientProjectsEvent {
  const ClientProjectsEvent();
}

/// The page opened, the user pulled to refresh, or tapped retry.
final class ClientProjectsFetched extends ClientProjectsEvent {
  const ClientProjectsFetched();
}
