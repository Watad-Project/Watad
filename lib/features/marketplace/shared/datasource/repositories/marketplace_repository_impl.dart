import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/marketplace/shared/datasource/remote/marketplace_remote_data_source.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_query.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  const MarketplaceRepositoryImpl(this._remote);

  final MarketplaceRemoteDataSource _remote;

  @override
  Future<Result<List<MarketplaceItem>>> getItems(MarketplaceQuery query) =>
      guardSupabaseCall(() => _remote.getItems(query));
}
