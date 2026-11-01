import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

class SetMarketplaceItemActiveUseCase
    implements UseCase<void, ({String itemId, bool isActive})> {
  const SetMarketplaceItemActiveUseCase(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Result<void>> call(({String itemId, bool isActive}) params) =>
      _repository.setItemActive(params.itemId, isActive: params.isActive);
}
