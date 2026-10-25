part of 'admin_users_bloc.dart';

sealed class AdminUsersEvent {
  const AdminUsersEvent();
}

/// Load the first page and the counts: at the start, on pull to refresh,
/// on retry and back from a user's page.
final class AdminUsersFetched extends AdminUsersEvent {
  const AdminUsersFetched();
}

/// A chip was picked.
final class AdminUsersFilterChanged extends AdminUsersEvent {
  const AdminUsersFilterChanged(this.filter);

  final AdminUsersFilter filter;
}

/// The search text changed.
final class AdminUsersSearchChanged extends AdminUsersEvent {
  const AdminUsersSearchChanged(this.search);

  final String search;
}

/// The list reached its end: load the next page.
final class AdminUsersMoreRequested extends AdminUsersEvent {
  const AdminUsersMoreRequested();
}
