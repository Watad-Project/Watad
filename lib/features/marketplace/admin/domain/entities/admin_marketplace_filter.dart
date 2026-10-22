import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item_status.dart';

/// The chips of the listings: «الكل», «معروضة», «مخفية», «محذوفة من الإدارة»
/// and «نفد المخزون».
enum AdminMarketplaceFilter {
  all(null),
  live(AdminMarketplaceItemStatus.live),
  hidden(AdminMarketplaceItemStatus.hidden),
  removed(AdminMarketplaceItemStatus.removed),
  outOfStock(AdminMarketplaceItemStatus.outOfStock);

  const AdminMarketplaceFilter(this.status);

  /// The status this chip shows; null shows every listing.
  final AdminMarketplaceItemStatus? status;

  bool matches(AdminMarketplaceItem item) =>
      status == null || item.status == status;
}
