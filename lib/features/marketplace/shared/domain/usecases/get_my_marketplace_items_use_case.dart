import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

class GetMyMarketplaceItemsUseCase
    implements UseCase<List<MarketplaceItem>, NoParams> {
  const GetMyMarketplaceItemsUseCase(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Result<List<MarketplaceItem>>> call([
    NoParams params = const NoParams(),
  ]) => _repository.getMyItems();
}
