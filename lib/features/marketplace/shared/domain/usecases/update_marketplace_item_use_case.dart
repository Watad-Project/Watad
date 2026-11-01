import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_draft.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

class UpdateMarketplaceItemUseCase
    implements
        UseCase<
          MarketplaceItem,
          ({String itemId, MarketplaceItemDraft draft})
        > {
  const UpdateMarketplaceItemUseCase(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Result<MarketplaceItem>> call(
    ({String itemId, MarketplaceItemDraft draft}) params,
  ) => _repository.updateItem(params.itemId, params.draft);
}
