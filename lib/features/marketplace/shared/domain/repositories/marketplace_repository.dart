import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_query.dart';

abstract interface class MarketplaceRepository {
  /// One page of active listings from `v_marketplace_items`.
  Future<Result<List<MarketplaceItem>>> getItems(MarketplaceQuery query);
}
