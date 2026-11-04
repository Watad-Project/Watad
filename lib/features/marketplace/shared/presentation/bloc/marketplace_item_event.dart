part of 'marketplace_item_bloc.dart';

sealed class MarketplaceItemEvent {
  const MarketplaceItemEvent();
}

/// The page opened, came back from editing, or the user tapped retry.
final class MarketplaceItemFetched extends MarketplaceItemEvent {
  const MarketplaceItemFetched(this.itemId);

  final String itemId;
}

/// The − or + of the quantity was tapped.
final class MarketplaceItemQuantityChanged extends MarketplaceItemEvent {
  const MarketplaceItemQuantityChanged(this.quantity);

  final int quantity;
}

/// «أضف للسلة» was tapped.
final class MarketplaceItemAddedToCart extends MarketplaceItemEvent {
  const MarketplaceItemAddedToCart();
}
