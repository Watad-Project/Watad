import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_addition.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/add_to_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_marketplace_item_use_case.dart';

part 'marketplace_item_event.dart';
part 'marketplace_item_state.dart';

/// One listing's details page: the item, the quantity to add, and
/// «أضف للسلة».
class MarketplaceItemBloc
    extends Bloc<MarketplaceItemEvent, MarketplaceItemState> {
  MarketplaceItemBloc(this._getItem, this._addToCart)
    : super(const MarketplaceItemState()) {
    on<MarketplaceItemFetched>(_onFetched);
    on<MarketplaceItemQuantityChanged>(_onQuantityChanged);
    on<MarketplaceItemAddedToCart>(_onAddedToCart);
  }

  final GetMarketplaceItemUseCase _getItem;
  final AddToCartUseCase _addToCart;

  Future<void> _onFetched(
    MarketplaceItemFetched event,
    Emitter<MarketplaceItemState> emit,
  ) async {
    emit(
      state.copyWith(
        itemId: event.itemId,
        status: MarketplaceItemLoadStatus.loading,
      ),
    );
    final result = await _getItem(event.itemId);
    switch (result) {
      case Success(:final data?):
        emit(
          state.copyWith(
            status: MarketplaceItemLoadStatus.success,
            item: () => data,
            quantity: _clamp(state.quantity, data),
            failure: () => null,
          ),
        );
      case Success():
        emit(
          state.copyWith(
            status: MarketplaceItemLoadStatus.unavailable,
            item: () => null,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MarketplaceItemLoadStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  void _onQuantityChanged(
    MarketplaceItemQuantityChanged event,
    Emitter<MarketplaceItemState> emit,
  ) {
    final item = state.item;
    if (item == null) return;
    emit(state.copyWith(quantity: _clamp(event.quantity, item)));
  }

  Future<void> _onAddedToCart(
    MarketplaceItemAddedToCart event,
    Emitter<MarketplaceItemState> emit,
  ) async {
    final item = state.item;
    if (item == null || state.addStatus == MarketplaceItemAddStatus.adding) {
      return;
    }
    emit(state.copyWith(addStatus: MarketplaceItemAddStatus.adding));
    final result = await _addToCart((item: item, quantity: state.quantity));
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            addStatus: MarketplaceItemAddStatus.added,
            addition: () => data,
            addFailure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            addStatus: MarketplaceItemAddStatus.failed,
            addFailure: () => failure,
          ),
        );
    }
  }

  /// From 1 to the stock (1 when it is out of stock: the button is off).
  static int _clamp(int quantity, MarketplaceItem item) =>
      quantity.clamp(1, max(1, item.stockQuantity));
}
