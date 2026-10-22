import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_removal.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_get_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/admin/domain/usecases/admin_remove_marketplace_item_use_case.dart';

part 'admin_marketplace_item_event.dart';
part 'admin_marketplace_item_state.dart';

/// One listing and «إزالة المنتج». After the removal the listing is read
/// again, so the page shows what the server saved.
class AdminMarketplaceItemBloc
    extends Bloc<AdminMarketplaceItemEvent, AdminMarketplaceItemState> {
  AdminMarketplaceItemBloc(this._getItem, this._removeItem)
    : super(const AdminMarketplaceItemState()) {
    on<AdminMarketplaceItemFetched>(_onFetched);
    on<AdminMarketplaceItemRemoved>(_onRemoved);
  }

  final AdminGetMarketplaceItemUseCase _getItem;
  final AdminRemoveMarketplaceItemUseCase _removeItem;

  Future<void> _onFetched(
    AdminMarketplaceItemFetched event,
    Emitter<AdminMarketplaceItemState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminMarketplaceItemLoadStatus.loading,
        itemId: event.itemId,
      ),
    );
    final result = await _getItem(event.itemId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: AdminMarketplaceItemLoadStatus.success,
            item: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: AdminMarketplaceItemLoadStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onRemoved(
    AdminMarketplaceItemRemoved event,
    Emitter<AdminMarketplaceItemState> emit,
  ) async {
    final item = state.item;
    if (item == null || state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    final result = await _removeItem(
      AdminMarketplaceRemoval(item: item, reason: event.reason),
    );
    // Also after a failure: e.g. another admin removed it meanwhile.
    final fresh = await _getItem(item.id);
    emit(
      state.copyWith(
        item: fresh is Success<AdminMarketplaceItem> ? () => fresh.data : null,
        isBusy: false,
        message: () => switch (result) {
          Success() => const AdminMarketplaceItemMessage(
            'marketplace.removed_done',
            isError: false,
          ),
          // The listing is gone: say so, not just "not found".
          Failed(failure: NotFoundFailure()) =>
            const AdminMarketplaceItemMessage(
              'marketplace.error_not_found',
              isError: true,
            ),
          Failed(:final failure) => AdminMarketplaceItemMessage(
            failure.messageKey,
            isError: true,
          ),
        },
      ),
    );
  }
}
