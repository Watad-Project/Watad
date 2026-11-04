import 'package:watad/core/enums/payment_method.dart';

/// What a demo payment is made with, as `simulate_order_payment()` records
/// it (`p_card_brand`). Shown as text only: the app has no licensed logos.
enum PaymentBrand {
  visa('Visa'),
  mastercard('Mastercard'),
  mada('mada'),
  applePay('Apple Pay'),
  stcPay('STC Pay');

  const PaymentBrand(this.value);

  /// The text sent as `p_card_brand`.
  final String value;

  /// Apple Pay or STC Pay for those methods; null for a card method.
  static PaymentBrand? walletOf(PaymentMethod method) => switch (method) {
    PaymentMethod.applePay => PaymentBrand.applePay,
    PaymentMethod.stcPay => PaymentBrand.stcPay,
    _ => null,
  };

  /// The network of a «بطاقة ائتمانية» from its digits: Visa starts with 4,
  /// Mastercard with 51–55 or 2221–2720. Null for any other card.
  static PaymentBrand? creditCardOf(String digits) {
    if (digits.startsWith('4')) return PaymentBrand.visa;
    if (digits.length < 4) return null;
    final two = int.parse(digits.substring(0, 2));
    final four = int.parse(digits.substring(0, 4));
    if ((two >= 51 && two <= 55) || (four >= 2221 && four <= 2720)) {
      return PaymentBrand.mastercard;
    }
    return null;
  }
}
