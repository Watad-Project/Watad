part of 'payment_bloc.dart';

sealed class PaymentEvent {
  const PaymentEvent();
}

/// The page opened for [orderId].
final class PaymentStarted extends PaymentEvent {
  const PaymentStarted(this.orderId);

  final String orderId;
}

/// «حاول مرة أخرى»: read the order again and show the form.
final class PaymentRetried extends PaymentEvent {
  const PaymentRetried();
}

/// The card form was sent. The fields are checked on the phone right away
/// and never kept: only the brand and the last 4 digits go on.
final class PaymentCardSubmitted extends PaymentEvent {
  const PaymentCardSubmitted({
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.name,
  });

  final String number;
  final String expiry;
  final String cvv;
  final String name;
}

/// «تأكيد الدفع» on the Apple Pay or STC Pay sheet.
final class PaymentWalletConfirmed extends PaymentEvent {
  const PaymentWalletConfirmed();
}
