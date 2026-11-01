part of 'marketplace_bloc.dart';

sealed class MarketplaceEvent {
  const MarketplaceEvent();
}

/// Load the first page: at the start, on pull to refresh, and on retry.
final class MarketplaceFetched extends MarketplaceEvent {
  const MarketplaceFetched();
}

/// A category chip was picked (`null` means "All").
final class MarketplaceCategoryChanged extends MarketplaceEvent {
  const MarketplaceCategoryChanged(this.category);

  final MarketplaceCategory? category;
}

/// The sort order changed.
final class MarketplaceSortChanged extends MarketplaceEvent {
  const MarketplaceSortChanged(this.sort);

  final MarketplaceSort sort;
}

/// The search text changed.
final class MarketplaceSearchChanged extends MarketplaceEvent {
  const MarketplaceSearchChanged(this.search);

  final String search;
}

/// The list reached its end: load the next page.
final class MarketplaceMoreRequested extends MarketplaceEvent {
  const MarketplaceMoreRequested();
}
