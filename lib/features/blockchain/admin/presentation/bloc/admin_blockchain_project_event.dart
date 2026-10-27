part of 'admin_blockchain_project_bloc.dart';

sealed class AdminBlockchainProjectEvent {
  const AdminBlockchainProjectEvent();
}

/// Load the project: when the page opens, on retry, pull to refresh and a
/// moment after a resync.
final class AdminBlockchainProjectFetched extends AdminBlockchainProjectEvent {
  const AdminBlockchainProjectFetched(this.projectId);

  final String projectId;
}

/// «إعادة المزامنة الآن», after the admin confirmed.
final class AdminBlockchainProjectResynced extends AdminBlockchainProjectEvent {
  const AdminBlockchainProjectResynced();
}
