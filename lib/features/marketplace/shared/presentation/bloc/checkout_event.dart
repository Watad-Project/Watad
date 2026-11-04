part of 'checkout_bloc.dart';

sealed class CheckoutEvent {
  const CheckoutEvent();
}

/// The page opened for [sellerId]'s group, or retry.
final class CheckoutStarted extends CheckoutEvent {
  const CheckoutStarted(this.sellerId);

  final String sellerId;
}

/// A delivery address was picked.
final class CheckoutAddressSelected extends CheckoutEvent {
  const CheckoutAddressSelected(this.addressId);

  final String addressId;
}

/// A payment method was picked.
final class CheckoutMethodSelected extends CheckoutEvent {
  const CheckoutMethodSelected(this.method);

  final PaymentMethod method;
}

/// The map picker saved a new address: reload and pick it.
final class CheckoutAddressAdded extends CheckoutEvent {
  const CheckoutAddressAdded(this.addressId);

  final String addressId;
}

/// «تأكيد الطلب» was tapped.
final class CheckoutSubmitted extends CheckoutEvent {
  const CheckoutSubmitted();
}
