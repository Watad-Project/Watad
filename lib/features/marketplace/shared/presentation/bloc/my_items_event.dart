part of 'my_items_bloc.dart';

sealed class MyItemsEvent {
  const MyItemsEvent();
}

/// Load the signed-in seller's listings.
final class MyItemsFetched extends MyItemsEvent {
  const MyItemsFetched();
}

/// A status filter chip was selected.
final class MyItemsFilterChanged extends MyItemsEvent {
  const MyItemsFilterChanged(this.filter);

  final MyItemsFilter filter;
}

/// Hide or show one of the seller's listings (`is_active`).
final class MyItemVisibilityToggled extends MyItemsEvent {
  const MyItemVisibilityToggled({required this.itemId, required this.isActive});

  final String itemId;
  final bool isActive;
}

/// Soft-delete one of the seller's listings (`deleted_at`).
final class MyItemDeleted extends MyItemsEvent {
  const MyItemDeleted(this.itemId);

  final String itemId;
}
