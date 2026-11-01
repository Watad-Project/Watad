part of 'cart_count_bloc.dart';

final class CartCountState {
  const CartCountState({this.count = 0, this.failure});

  /// Lines in the cart.
  final int count;

  /// Why the last refresh failed; null after a good one.
  final Failure? failure;
}
