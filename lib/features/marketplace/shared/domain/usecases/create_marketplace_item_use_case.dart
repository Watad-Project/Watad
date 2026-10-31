import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item_draft.dart';
import 'package:watad/features/marketplace/shared/domain/repositories/marketplace_repository.dart';

class CreateMarketplaceItemUseCase
    implements UseCase<MarketplaceItem, MarketplaceItemDraft> {
  const CreateMarketplaceItemUseCase(this._repository);

  final MarketplaceRepository _repository;

  @override
  Future<Result<MarketplaceItem>> call(MarketplaceItemDraft draft) =>
      _repository.createItem(draft);
}
