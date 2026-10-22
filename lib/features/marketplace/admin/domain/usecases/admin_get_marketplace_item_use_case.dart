import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/repositories/admin_marketplace_repository.dart';

/// One listing, for its page; the parameter is its id.
class AdminGetMarketplaceItemUseCase
    implements UseCase<AdminMarketplaceItem, String> {
  const AdminGetMarketplaceItemUseCase(this._repository);

  final AdminMarketplaceRepository _repository;

  @override
  Future<Result<AdminMarketplaceItem>> call(String params) =>
      _repository.getItem(params);
}
