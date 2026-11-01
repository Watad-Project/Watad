import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/remove_from_cart_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/restore_cart_line_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/set_cart_quantity_use_case.dart';

part 'cart_event.dart';
part 'cart_state.dart';

/// The cart screen: the lines re-read from the server, grouped by seller;
/// change a quantity, remove a line and undo it.
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._getCart, this._setQuantity, this._remove, this._restore)
    : super(const CartState()) {
    on<CartFetched>((event, emit) => _load(emit));
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartLineRemoved>(_onLineRemoved);
    on<CartLineRestored>(_onLineRestored);
  }

  final GetCartUseCase _getCart;
  final SetCartQuantityUseCase _setQuantity;
  final RemoveFromCartUseCase _remove;
  final RestoreCartLineUseCase _restore;

  Future<void> _load(Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.loading));
    final result = await _getCart();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: CartStatus.success,
            cart: data,
            failure: () => null,
          ),
        );
      case Failed(:final failure) when state.hasLoaded:
        // The cart stays on screen; a snackbar says why it didn't refresh.
        emit(
          state.copyWith(
            status: CartStatus.success,
            actionFailure: () => failure,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(status: CartStatus.failure, failure: () => failure),
        );
    }
  }

  Future<void> _onQuantityChanged(
    CartQuantityChanged event,
    Emitter<CartState> emit,
  ) async {
    final previous = state.cart;
    emit(
      state.copyWith(
        cart: previous.withQuantity(event.itemId, event.quantity),
        actionFailure: () => null,
      ),
    );
    final result = await _setQuantity((
      itemId: event.itemId,
      quantity: event.quantity,
    ));
    if (result case Failed(:final failure)) {
      emit(state.copyWith(cart: previous, actionFailure: () => failure));
    }
  }

  Future<void> _onLineRemoved(
    CartLineRemoved event,
    Emitter<CartState> emit,
  ) async {
    final result = await _remove(event.itemId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            cart: state.cart.without(event.itemId),
            lastRemoved: () => data,
            actionFailure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(state.copyWith(actionFailure: () => failure));
    }
  }

  Future<void> _onLineRestored(
    CartLineRestored event,
    Emitter<CartState> emit,
  ) async {
    final removed = state.lastRemoved;
    if (removed == null) return;
    emit(state.copyWith(lastRemoved: () => null));
    final result = await _restore(removed);
    switch (result) {
      case Success():
        await _load(emit);
      case Failed(:final failure):
        emit(state.copyWith(actionFailure: () => failure));
    }
  }
}
