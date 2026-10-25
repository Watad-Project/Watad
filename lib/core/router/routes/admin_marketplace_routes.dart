/// The routes of lib/features/marketplace/admin/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
abstract final class AdminMarketplaceRoutes {
  static const String marketplaceName = 'admin-marketplace';
  static const String marketplacePath = '/admin/marketplace';
  static const String marketplaceItemName = 'admin-marketplace-item';
  static const String marketplaceItemPath = '/admin/marketplace/:itemId';
}
