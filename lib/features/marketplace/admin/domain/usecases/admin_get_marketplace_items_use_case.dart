import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_query.dart';
import 'package:watad/features/marketplace/admin/domain/repositories/admin_marketplace_repository.dart';

/// One page of the listings.
class AdminGetMarketplaceItemsUseCase
    implements UseCase<List<AdminMarketplaceItem>, AdminMarketplaceQuery> {
  const AdminGetMarketplaceItemsUseCase(this._repository);

  final AdminMarketplaceRepository _repository;

  @override
  Future<Result<List<AdminMarketplaceItem>>> call(
    AdminMarketplaceQuery params,
  ) => _repository.getItems(params);
}
