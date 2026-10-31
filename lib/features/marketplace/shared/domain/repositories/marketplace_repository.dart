import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_draft.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_query.dart';

/// Reads and writes marketplace listings (`v_marketplace_items`,
/// `marketplace_items`, and `set_marketplace_item_photos`).
abstract interface class MarketplaceRepository {
  /// One page of active listings matching [query].
  Future<Result<List<MarketplaceItem>>> getItems(MarketplaceQuery query);

  /// The signed-in seller's listings (`is_mine = true`), newest first.
  Future<Result<List<MarketplaceItem>>> getMyItems();

  /// One of the signed-in seller's listings (`is_mine = true`).
  Future<Result<MarketplaceItem>> getMyItem(String itemId);

  /// Creates a new listing and uploads/saves its photos.
  Future<Result<MarketplaceItem>> createItem(MarketplaceItemDraft draft);

  /// Updates an existing listing (while not removed) and its photos.
  Future<Result<MarketplaceItem>> updateItem(
    String itemId,
    MarketplaceItemDraft draft,
  );

  /// Shows (`isActive = true`) or hides (`isActive = false`) a listing.
  Future<Result<void>> setItemActive(String itemId, {required bool isActive});

  /// Soft-deletes a listing (`deleted_at = now()`).
  Future<Result<void>> deleteItem(String itemId);
}
