/// The routes of lib/features/marketplace/shared/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class MarketplaceRoutes {
  static const String marketplaceName = 'marketplace';
  static const String marketplacePath = '/marketplace';

  static const String myItemsName = 'my-items';
  static const String myItemsPath = '/marketplace/my-items';

  static const String newMyItemName = 'new-my-item';
  static const String newMyItemPath = '/marketplace/my-items/new';

  static const String editMyItemName = 'edit-my-item';
  static const String editMyItemPath = '/marketplace/my-items/:itemId/edit';

  /// One listing (GRA-67). Under `items/`, so `/marketplace/<id>` never
  /// catches `my-items`, `cart` or `orders`.
  static const String marketplaceItemName = 'marketplace-item';
  static const String marketplaceItemPath = '/marketplace/items/:itemId';

  /// The cart, grouped by seller (GRA-68).
  static const String marketplaceCartName = 'marketplace-cart';
  static const String marketplaceCartPath = '/marketplace/cart';

  /// One seller's group from the cart (GRA-68).
  static const String marketplaceCheckoutName = 'marketplace-checkout';
  static const String marketplaceCheckoutPath =
      '/marketplace/checkout/:sellerId';

  /// The demo payment of an unpaid order (GRA-68).
  static const String marketplacePaymentName = 'marketplace-payment';
  static const String marketplacePaymentPath =
      '/marketplace/orders/:orderId/pay';
}
