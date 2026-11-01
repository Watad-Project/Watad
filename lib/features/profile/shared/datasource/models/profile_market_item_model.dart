import 'package:watad/core/utils/money.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_market_item.dart';

class ProfileMarketItemModel extends ProfileMarketItem {
  const ProfileMarketItemModel({
    required super.id,
    required super.name,
    required super.price,
    required super.inStock,
    super.photoUrl,
  });

  /// Maps the `v_marketplace_items` columns selected in
  /// ProfileRemoteDataSourceImpl, plus `photo_url` (the first photo's public
  /// URL), which the data source adds.
  factory ProfileMarketItemModel.fromJson(Map<String, dynamic> json) {
    return ProfileMarketItemModel(
      id: json['id'] as String,
      name: json['item_name'] as String,
      price: Money.fromJson(json['price'] as num),
      inStock: json['in_stock'] as bool? ?? false,
      photoUrl: json['photo_url'] as String?,
    );
  }
}
