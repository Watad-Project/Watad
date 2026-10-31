import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_status.dart';

/// A listing from `v_marketplace_items`: the item, its photos in order, its
/// category, whether it is in stock or removed by an admin, and the seller's
/// public card.
class MarketplaceItem {
  const MarketplaceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
    required this.inStock,
    required this.isActive,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.sellerId,
    required this.sellerName,
    this.description,
    this.photoPaths = const [],
    this.photoUrls = const [],
    this.sellerAvatarUrl,
    this.sellerIsVerifiedBusiness = false,
    this.sellerRatingAvg,
    this.sellerRatingCount = 0,
    this.isMine = false,
    this.removedAt,
    this.removalReason,
  });

  final String id;
  final String name;
  final String? description;
  final Money price;
  final int stockQuantity;
  final bool inStock;
  final bool isActive;
  final MarketplaceCategory category;
  final List<String> photoPaths;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;
  final bool sellerIsVerifiedBusiness;
  final double? sellerRatingAvg;
  final int sellerRatingCount;
  final bool isMine;
  final DateTime? removedAt;
  final String? removalReason;

  /// The first photo's public URL, or null when the listing has no photos.
  String? get firstPhotoUrl => photoUrls.isEmpty ? null : photoUrls.first;

  /// Whether an admin removed this listing (`removed_at != null`).
  bool get isRemoved => removedAt != null;

  /// The listing's status for the seller's «منتجاتي» chips.
  MarketplaceItemStatus get status {
    if (isRemoved) return MarketplaceItemStatus.removed;
    if (!isActive) return MarketplaceItemStatus.hidden;
    if (!inStock) return MarketplaceItemStatus.outOfStock;
    return MarketplaceItemStatus.live;
  }
}
