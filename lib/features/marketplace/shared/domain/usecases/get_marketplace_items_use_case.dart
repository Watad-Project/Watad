import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_query.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

/// Reads one page of active marketplace listings matching [MarketplaceQuery].
class GetMarketplaceItemsUseCase
    implements UseCase<List<MarketplaceItem>, MarketplaceQuery> {
  const GetMarketplaceItemsUseCase(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Result<List<MarketplaceItem>>> call(MarketplaceQuery params) =>
      _repository.getItems(params);
}
