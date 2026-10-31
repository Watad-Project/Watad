import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/my_items_filter.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/delete_marketplace_item_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_marketplace_items_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/set_marketplace_item_active_use_case.dart';

part 'my_items_event.dart';
part 'my_items_state.dart';

/// Manages the signed-in seller's listings on `/marketplace/my-items`:
/// filtering by status chip, hiding/showing (`is_active`), and soft-deleting
/// (`deleted_at`).
class MyItemsBloc extends Bloc<MyItemsEvent, MyItemsState> {
  MyItemsBloc(this._getMyItems, this._setItemActive, this._deleteItem)
    : super(const MyItemsState()) {
    on<MyItemsFetched>(_onFetched);
    on<MyItemsFilterChanged>(
      (event, emit) => emit(state.copyWith(filter: event.filter)),
    );
    on<MyItemVisibilityToggled>(_onVisibilityToggled);
    on<MyItemDeleted>(_onDeleted);
  }

  final GetMyMarketplaceItemsUseCase _getMyItems;
  final SetMarketplaceItemActiveUseCase _setItemActive;
  final DeleteMarketplaceItemUseCase _deleteItem;

  Future<void> _onFetched(
    MyItemsFetched event,
    Emitter<MyItemsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: MyItemsStatus.loading,
        failure: () => null,
        actionFailure: () => null,
        actionDoneKey: () => null,
      ),
    );
    switch (await _getMyItems()) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: MyItemsStatus.success,
            items: data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(status: MyItemsStatus.failure, failure: () => failure),
        );
    }
  }

  Future<void> _onVisibilityToggled(
    MyItemVisibilityToggled event,
    Emitter<MyItemsState> emit,
  ) async {
    if (state.busyItemId != null) return;
    emit(
      state.copyWith(
        busyItemId: () => event.itemId,
        actionFailure: () => null,
        actionDoneKey: () => null,
      ),
    );
    final result = await _setItemActive((
      itemId: event.itemId,
      isActive: event.isActive,
    ));
    switch (result) {
      case Success():
        final refreshed = await _getMyItems();
        emit(
          state.copyWith(
            busyItemId: () => null,
            items: switch (refreshed) {
              Success(:final data) => data,
              Failed() => state.items,
            },
            actionDoneKey: () => event.isActive
                ? 'marketplace.my_items_shown_done'
                : 'marketplace.my_items_hidden_done',
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(busyItemId: () => null, actionFailure: () => failure),
        );
    }
  }

  Future<void> _onDeleted(
    MyItemDeleted event,
    Emitter<MyItemsState> emit,
  ) async {
    if (state.busyItemId != null) return;
    emit(
      state.copyWith(
        busyItemId: () => event.itemId,
        actionFailure: () => null,
        actionDoneKey: () => null,
      ),
    );
    switch (await _deleteItem(event.itemId)) {
      case Success():
        final refreshed = await _getMyItems();
        emit(
          state.copyWith(
            busyItemId: () => null,
            items: switch (refreshed) {
              Success(:final data) => data,
              Failed() => [
                for (final item in state.items)
                  if (item.id != event.itemId) item,
              ],
            },
            actionDoneKey: () => 'marketplace.my_items_deleted_done',
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(busyItemId: () => null, actionFailure: () => failure),
        );
    }
  }
}
