part of 'cart_bloc.dart';

enum CartStatus { initial, loading, success, failure }

final class CartState {
  const CartState({
    this.status = CartStatus.initial,
    this.cart = const Cart(),
    this.failure,
    this.actionFailure,
    this.lastRemoved,
  });

  final CartStatus status;
  final Cart cart;

  /// Why the cart couldn't load the first time.
  final Failure? failure;

  /// Why a refresh, a quantity change or a removal failed.
  final Failure? actionFailure;

  /// The line «تراجع» puts back.
  final ({CartLine line, int index})? lastRemoved;

  /// The cart has been on screen at least once.
  bool get hasLoaded =>
      status == CartStatus.success ||
      (status == CartStatus.loading && !cart.isEmpty);

  CartState copyWith({
    CartStatus? status,
    Cart? cart,
    Failure? Function()? failure,
    Failure? Function()? actionFailure,
    ({CartLine line, int index})? Function()? lastRemoved,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      failure: failure == null ? this.failure : failure(),
      actionFailure: actionFailure == null
          ? this.actionFailure
          : actionFailure(),
      lastRemoved: lastRemoved == null ? this.lastRemoved : lastRemoved(),
    );
  }
}
