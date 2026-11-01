import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/utils/money.dart';

/// The fields a seller submits when creating or editing a marketplace listing.
class MarketplaceItemDraft {
  const MarketplaceItemDraft({
    required this.name,
    required this.price,
    required this.stockQuantity,
    required this.category,
    this.description,
    this.photos = const [],
    this.isActive = true,
  });

  final String name;
  final String? description;
  final Money price;
  final int stockQuantity;
  final MarketplaceCategory category;

  /// Up to 6 photo references in order: each is either an existing storage
  /// path in `images` (`<sellerId>/marketplace/<itemId>/<file>`) or a local
  /// file path on the device to upload.
  final List<String> photos;

  final bool isActive;
}
