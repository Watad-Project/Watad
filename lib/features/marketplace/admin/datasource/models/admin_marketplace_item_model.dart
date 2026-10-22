import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item_status.dart';

class AdminMarketplaceItemModel extends AdminMarketplaceItem {
  const AdminMarketplaceItemModel({
    required super.id,
    required super.name,
    required super.price,
    required super.stock,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required super.sellerId,
    required super.sellerName,
    super.description,
    super.sellerAvatarUrl,
    super.sellerIsVerified,
    super.sellerRatingAvg,
    super.sellerRatingCount,
    super.removedAt,
    super.removalReason,
    super.removedByName,
    super.orderCount,
    super.openReportCount,
  });

  /// The `status` of a `v_admin_marketplace_items` row, and back.
  static AdminMarketplaceItemStatus statusOf(String value) => switch (value) {
    'live' => AdminMarketplaceItemStatus.live,
    'removed' => AdminMarketplaceItemStatus.removed,
    'out_of_stock' => AdminMarketplaceItemStatus.outOfStock,
    _ => AdminMarketplaceItemStatus.hidden,
  };

  static String valueOf(AdminMarketplaceItemStatus status) => switch (status) {
    AdminMarketplaceItemStatus.live => 'live',
    AdminMarketplaceItemStatus.hidden => 'hidden',
    AdminMarketplaceItemStatus.removed => 'removed',
    AdminMarketplaceItemStatus.outOfStock => 'out_of_stock',
  };

  /// Maps the `v_admin_marketplace_items` columns selected in
  /// AdminMarketplaceRemoteDataSourceImpl, plus `seller_avatar_url`, the
  /// public URL of `seller_avatar_path` that the data source adds.
  factory AdminMarketplaceItemModel.fromJson(Map<String, dynamic> json) {
    int count(String column) => (json[column] as num?)?.toInt() ?? 0;
    final removedAt = json['removed_at'] as String?;
    return AdminMarketplaceItemModel(
      id: json['id'] as String,
      name: json['item_name'] as String,
      description: json['description'] as String?,
      price: Money.fromJson(json['price'] as num),
      stock: count('stock_quantity'),
      status: statusOf(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String? ?? '',
      sellerAvatarUrl: json['seller_avatar_url'] as String?,
      sellerIsVerified: json['seller_is_verified_business'] as bool? ?? false,
      sellerRatingAvg: (json['seller_rating_avg'] as num?)?.toDouble(),
      sellerRatingCount: count('seller_rating_count'),
      removedAt: removedAt == null ? null : DateTime.parse(removedAt),
      removalReason: json['removal_reason'] as String?,
      removedByName: json['removed_by_name'] as String?,
      orderCount: count('order_count'),
      openReportCount: count('open_report_count'),
    );
  }
}
