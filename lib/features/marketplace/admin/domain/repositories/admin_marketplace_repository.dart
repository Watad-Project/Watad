import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_counts.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_query.dart';

abstract interface class AdminMarketplaceRepository {
  /// One page of listings, newest first.
  Future<Result<List<AdminMarketplaceItem>>> getItems(
    AdminMarketplaceQuery query,
  );

  /// How many listings each chip has, for [search].
  Future<Result<AdminMarketplaceCounts>> countItems(String search);

  /// One listing; [NotFoundFailure] when there is none with [itemId].
  Future<Result<AdminMarketplaceItem>> getItem(String itemId);

  /// Hides the listing and cancels its orders still waiting for payment.
  /// The seller reads [reason].
  Future<Result<void>> removeItem(String itemId, String reason);
}
