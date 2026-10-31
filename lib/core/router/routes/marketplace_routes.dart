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
}
