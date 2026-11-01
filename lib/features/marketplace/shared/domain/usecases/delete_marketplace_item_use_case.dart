import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

class DeleteMarketplaceItemUseCase implements UseCase<void, String> {
  const DeleteMarketplaceItemUseCase(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Result<void>> call(String itemId) => _repository.deleteItem(itemId);
}
