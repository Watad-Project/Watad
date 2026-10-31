import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

class GetMyMarketplaceItemUseCase implements UseCase<MarketplaceItem, String> {
  const GetMyMarketplaceItemUseCase(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Result<MarketplaceItem>> call(String itemId) =>
      _repository.getMyItem(itemId);
}
