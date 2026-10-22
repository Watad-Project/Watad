part of 'admin_marketplace_item_bloc.dart';

sealed class AdminMarketplaceItemEvent {
  const AdminMarketplaceItemEvent();
}

/// Load the listing: when the page opens, and on retry.
final class AdminMarketplaceItemFetched extends AdminMarketplaceItemEvent {
  const AdminMarketplaceItemFetched(this.itemId);

  final String itemId;
}

/// «إزالة المنتج», after the admin confirmed and gave the reason.
final class AdminMarketplaceItemRemoved extends AdminMarketplaceItemEvent {
  const AdminMarketplaceItemRemoved(this.reason);

  final String reason;
}
