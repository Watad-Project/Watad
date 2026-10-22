import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_counts.dart';
import 'package:watad/features/marketplace/admin/domain/repositories/admin_marketplace_repository.dart';

/// The number on each chip; the parameter is the search.
class AdminCountMarketplaceItemsUseCase
    implements UseCase<AdminMarketplaceCounts, String> {
  const AdminCountMarketplaceItemsUseCase(this._repository);

  final AdminMarketplaceRepository _repository;

  @override
  Future<Result<AdminMarketplaceCounts>> call(String params) =>
      _repository.countItems(params.trim());
}
