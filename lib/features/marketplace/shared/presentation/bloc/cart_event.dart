part of 'cart_bloc.dart';

sealed class CartEvent {
  const CartEvent();
}

/// The page opened, came back from checkout, was pulled, or retry.
final class CartFetched extends CartEvent {
  const CartFetched();
}

/// The − or + of a line.
final class CartQuantityChanged extends CartEvent {
  const CartQuantityChanged(this.itemId, this.quantity);

  final String itemId;
  final int quantity;
}

/// «إزالة» on a line.
final class CartLineRemoved extends CartEvent {
  const CartLineRemoved(this.itemId);

  final String itemId;
}

/// «تراجع» on the snackbar after «إزالة».
final class CartLineRestored extends CartEvent {
  const CartLineRestored();
}
