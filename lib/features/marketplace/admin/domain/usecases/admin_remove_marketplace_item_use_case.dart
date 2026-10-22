import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_removal.dart';
import 'package:watad/features/marketplace/admin/domain/repositories/admin_marketplace_repository.dart';

/// «إزالة المنتج». The database refuses an item already removed with a
/// generic error, so that is told apart here first, with its own message;
/// a listing that no longer exists comes back as [NotFoundFailure].
class AdminRemoveMarketplaceItemUseCase
    implements UseCase<void, AdminMarketplaceRemoval> {
  const AdminRemoveMarketplaceItemUseCase(this._repository);

  final AdminMarketplaceRepository _repository;

  @override
  Future<Result<void>> call(AdminMarketplaceRemoval params) async {
    final reason = params.reason.trim();
    final refusal = switch (params.item) {
      final item when item.isRemoved => 'marketplace.error_already_removed',
      _ when reason.isEmpty => 'common.reason_required',
      _ when reason.length > AdminMarketplaceRemoval.maxReasonLength =>
        'marketplace.error_reason_too_long',
      _ => null,
    };
    if (refusal != null) return Failed(ValidationFailure(refusal));
    return _repository.removeItem(params.item.id, reason);
  }
}
