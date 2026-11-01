import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_status.dart';

/// Filter chips on the seller's «منتجاتي» screen: «الكل», «معروضة», «مخفية»,
/// «محذوفة من الإدارة», and «نفد المخزون».
enum MyItemsFilter {
  all(null),
  live(MarketplaceItemStatus.live),
  hidden(MarketplaceItemStatus.hidden),
  removed(MarketplaceItemStatus.removed),
  outOfStock(MarketplaceItemStatus.outOfStock);

  const MyItemsFilter(this.status);

  /// The status this chip shows; `null` shows every listing.
  final MarketplaceItemStatus? status;

  bool matches(MarketplaceItem item) => status == null || item.status == status;
}
