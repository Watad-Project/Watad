import 'package:watad/features/marketplace/shared/domain/entities/payment_brand.dart';

/// All of a payment that leaves the phone: the brand and the last 4 digits.
/// The full card number and the CVV never get here (ARCHITECTURE.md §15).
class CardPayment {
  const CardPayment({required this.brand, required this.last4});

  /// Apple Pay and STC Pay have no card number, but `p_card_last4` needs 4
  /// digits: `0000`. The order page never shows them for these two.
  const CardPayment.wallet(this.brand) : last4 = '0000';

  final PaymentBrand brand;
  final String last4;
}
