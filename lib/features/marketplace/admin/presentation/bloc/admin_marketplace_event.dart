part of 'admin_marketplace_bloc.dart';

sealed class AdminMarketplaceEvent {
  const AdminMarketplaceEvent();
}

/// Load the first page and the counts: at the start, on pull to refresh,
/// on retry and back from a listing's page.
final class AdminMarketplaceFetched extends AdminMarketplaceEvent {
  const AdminMarketplaceFetched();
}

/// A chip was picked.
final class AdminMarketplaceFilterChanged extends AdminMarketplaceEvent {
  const AdminMarketplaceFilterChanged(this.filter);

  final AdminMarketplaceFilter filter;
}

/// The search text changed.
final class AdminMarketplaceSearchChanged extends AdminMarketplaceEvent {
  const AdminMarketplaceSearchChanged(this.search);

  final String search;
}

/// The list reached its end: load the next page.
final class AdminMarketplaceMoreRequested extends AdminMarketplaceEvent {
  const AdminMarketplaceMoreRequested();
}
