import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

/// One listing for its details page, or null when it isn't available: the
/// view has no row (hidden or deleted by its seller, for anyone else) or an
/// admin removed it.
class GetMarketplaceItemUseCase implements UseCase<MarketplaceItem?, String> {
  const GetMarketplaceItemUseCase(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Result<MarketplaceItem?>> call(String itemId) async {
    final result = await _repository.getItem(itemId);
    return switch (result) {
      Success(:final data) when data == null || data.isRemoved => const Success(
        null,
      ),
      Success(:final data) => Success(data),
      Failed(:final failure) => Failed(failure),
    };
  }
}
