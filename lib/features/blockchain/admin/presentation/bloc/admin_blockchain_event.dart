part of 'admin_blockchain_bloc.dart';

sealed class AdminBlockchainEvent {
  const AdminBlockchainEvent();
}

/// Load everything and check the ledger: at the start, each time the tab
/// shows, on pull to refresh and back from a project.
final class AdminBlockchainFetched extends AdminBlockchainEvent {
  const AdminBlockchainFetched();
}

/// «فحص الآن»: check the ledger again.
final class AdminBlockchainHealthChecked extends AdminBlockchainEvent {
  const AdminBlockchainHealthChecked();
}

/// A chip above the projects was picked.
final class AdminBlockchainFilterChanged extends AdminBlockchainEvent {
  const AdminBlockchainFilterChanged(this.filter);

  final AdminBlockchainFilter filter;
}
