import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';

/// The card form, checked on the phone. Each error is a translation key,
/// null when that field is fine. Nothing here holds the full number or the
/// CVV.
class CardCheck {
  const CardCheck({
    this.payment,
    this.declines = false,
    this.numberError,
    this.expiryError,
    this.cvvError,
    this.nameError,
  });

  /// The brand and last 4 digits to pay with; null while a field is wrong.
  final CardPayment? payment;

  /// The demo's decline card, 4000 0000 0000 0002: the payment is sent as
  /// failed, to show the failure screen.
  final bool declines;

  final String? numberError;
  final String? expiryError;
  final String? cvvError;
  final String? nameError;
}
