import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';

class MarketplaceItemModel extends MarketplaceItem {
  const MarketplaceItemModel({
    required super.id,
    required super.name,
    required super.price,
    required super.stockQuantity,
    required super.inStock,
    required super.isActive,
    required super.category,
    required super.createdAt,
    required super.updatedAt,
    required super.sellerId,
    required super.sellerName,
    super.description,
    super.photoPaths,
    super.photoUrls,
    super.sellerAvatarUrl,
    super.sellerIsVerifiedBusiness,
    super.sellerRatingAvg,
    super.sellerRatingCount,
    super.isMine,
    super.removedAt,
    super.removalReason,
  });

  /// Maps a `v_marketplace_items` row, plus `photo_urls` and
  /// `seller_avatar_url` added by [MarketplaceRemoteDataSourceImpl].
  factory MarketplaceItemModel.fromJson(Map<String, dynamic> json) {
    final stock = (json['stock_quantity'] as num?)?.toInt() ?? 0;
    final removedAt = json['removed_at'] as String?;
    final category = json['category'] as String?;
    final rawPaths = json['photo_paths'] as List<dynamic>?;
    final rawUrls = json['photo_urls'] as List<dynamic>?;

    return MarketplaceItemModel(
      id: json['id'] as String,
      name: json['item_name'] as String,
      description: json['description'] as String?,
      price: Money.fromJson(json['price'] as num),
      stockQuantity: stock,
      inStock: json['in_stock'] as bool? ?? (stock > 0),
      isActive: json['is_active'] as bool? ?? true,
      category: category == null
          ? MarketplaceCategory.other
          : MarketplaceCategory.fromJson(category),
      photoPaths: rawPaths == null
          ? const []
          : rawPaths.whereType<String>().toList(),
      photoUrls: rawUrls == null
          ? const []
          : rawUrls.whereType<String>().toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String? ?? '',
      sellerAvatarUrl: json['seller_avatar_url'] as String?,
      sellerIsVerifiedBusiness:
          json['seller_is_verified_business'] as bool? ?? false,
      sellerRatingAvg: (json['seller_rating_avg'] as num?)?.toDouble(),
      sellerRatingCount: (json['seller_rating_count'] as num?)?.toInt() ?? 0,
      isMine: json['is_mine'] as bool? ?? false,
      removedAt: removedAt == null ? null : DateTime.parse(removedAt),
      removalReason: json['removal_reason'] as String?,
    );
  }
}
