part of 'payment_bloc.dart';

/// - [notPayable]: not mine as the buyer, not awaiting payment, or a bank
///   transfer: the page says so and links to the order.
/// - [declined]: the bank (the demo) said no; the order stays unpaid.
/// - [payFailure]: anything else went wrong while paying.
enum PaymentPageStatus {
  initial,
  loading,
  loadFailure,
  ready,
  notPayable,
  processing,
  paid,
  declined,
  payFailure,
}

final class PaymentState {
  const PaymentState({
    this.orderId = '',
    this.status = PaymentPageStatus.initial,
    this.order,
    this.cardCheck,
    this.failure,
  });

  final String orderId;
  final PaymentPageStatus status;
  final MarketplaceOrder? order;

  /// The card form's errors after a send that didn't pass; null otherwise.
  final CardCheck? cardCheck;

  /// Why the order couldn't load, or why paying failed.
  final Failure? failure;

  PaymentState copyWith({
    String? orderId,
    PaymentPageStatus? status,
    MarketplaceOrder? Function()? order,
    CardCheck? Function()? cardCheck,
    Failure? Function()? failure,
  }) {
    return PaymentState(
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      order: order == null ? this.order : order(),
      cardCheck: cardCheck == null ? this.cardCheck : cardCheck(),
      failure: failure == null ? this.failure : failure(),
    );
  }
}
