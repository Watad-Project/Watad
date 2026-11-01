import 'package:watad/core/utils/money.dart';

/// One of a user's active items on the market, for their public profile
/// (GRA-58): a `v_marketplace_items` row.
class ProfileMarketItem {
  const ProfileMarketItem({
    required this.id,
    required this.name,
    required this.price,
    required this.inStock,
    this.photoUrl,
  });

  final String id;
  final String name;
  final Money price;
  final bool inStock;

  /// The first photo's public URL; null when it has none.
  final String? photoUrl;
}
