part of 'cart_count_bloc.dart';

sealed class CartCountEvent {
  const CartCountEvent();
}

/// The browse tab opened, or came back from a page that may change the cart.
final class CartCountRefreshed extends CartCountEvent {
  const CartCountRefreshed();
}
