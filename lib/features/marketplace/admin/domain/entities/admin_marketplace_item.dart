import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item_status.dart';

/// A listing as an admin sees it: a `v_admin_marketplace_items` row.
class AdminMarketplaceItem {
  const AdminMarketplaceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.sellerId,
    required this.sellerName,
    this.description,
    this.sellerAvatarUrl,
    this.sellerIsVerified = false,
    this.sellerRatingAvg,
    this.sellerRatingCount = 0,
    this.removedAt,
    this.removalReason,
    this.removedByName,
    this.orderCount = 0,
    this.openReportCount = 0,
  });

  final String id;
  final String name;
  final String? description;

  /// Per unit.
  final Money price;
  final int stock;
  final AdminMarketplaceItemStatus status;

  /// When it was listed and last changed (UTC).
  final DateTime createdAt;
  final DateTime updatedAt;

  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;

  /// A verified business: the name gets the verified check.
  final bool sellerIsVerified;
  final double? sellerRatingAvg;
  final int sellerRatingCount;

  /// The removal by an admin, when it was removed.
  final DateTime? removedAt;
  final String? removalReason;
  final String? removedByName;

  /// Orders with this item, and reports about it still open or in review.
  final int orderCount;
  final int openReportCount;

  bool get isRemoved => status == AdminMarketplaceItemStatus.removed;
}
