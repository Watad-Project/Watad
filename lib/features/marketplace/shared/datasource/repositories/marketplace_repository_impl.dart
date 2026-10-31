import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/marketplace/shared/datasource/remote/marketplace_remote_data_source.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_draft.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_query.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  const MarketplaceRepositoryImpl(this._remote);

  final MarketplaceRemoteDataSource _remote;

  @override
  Future<Result<List<MarketplaceItem>>> getItems(MarketplaceQuery query) =>
      guardSupabaseCall(() => _remote.getItems(query));

  @override
  Future<Result<List<MarketplaceItem>>> getMyItems() =>
      guardSupabaseCall(_remote.getMyItems);

  @override
  Future<Result<MarketplaceItem>> getMyItem(String itemId) =>
      guardSupabaseCall(() => _remote.getMyItem(itemId));

  @override
  Future<Result<MarketplaceItem>> createItem(MarketplaceItemDraft draft) =>
      guardSupabaseCall(() => _remote.createItem(draft));

  @override
  Future<Result<MarketplaceItem>> updateItem(
    String itemId,
    MarketplaceItemDraft draft,
  ) => guardSupabaseCall(() => _remote.updateItem(itemId, draft));

  @override
  Future<Result<void>> setItemActive(String itemId, {required bool isActive}) =>
      guardSupabaseCall(
        () => _remote.setItemActive(itemId, isActive: isActive),
      );

  @override
  Future<Result<void>> deleteItem(String itemId) =>
      guardSupabaseCall(() => _remote.deleteItem(itemId));
}
