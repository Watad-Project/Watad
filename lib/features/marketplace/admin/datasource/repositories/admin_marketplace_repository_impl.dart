import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/marketplace/admin/datasource/remote/admin_marketplace_remote_data_source.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_counts.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_query.dart';
import 'package:watad/features/marketplace/admin/domain/repositories/admin_marketplace_repository.dart';

class AdminMarketplaceRepositoryImpl implements AdminMarketplaceRepository {
  const AdminMarketplaceRepositoryImpl(this._remote);

  final AdminMarketplaceRemoteDataSource _remote;

  @override
  Future<Result<List<AdminMarketplaceItem>>> getItems(
    AdminMarketplaceQuery query,
  ) => guardSupabaseCall(() => _remote.getItems(query));

  @override
  Future<Result<AdminMarketplaceCounts>> countItems(String search) =>
      guardSupabaseCall(
        () async => AdminMarketplaceCounts(await _remote.countItems(search)),
      );

  @override
  Future<Result<AdminMarketplaceItem>> getItem(String itemId) =>
      guardSupabaseCall(() => _remote.getItem(itemId));

  @override
  Future<Result<void>> removeItem(String itemId, String reason) =>
      guardSupabaseCall(() => _remote.removeItem(itemId, reason));
}
