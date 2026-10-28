import 'package:watad/core/utils/money.dart';

/// How the bank transfer screen writes an amount (GRA-52). The IBAN's
/// format is shared with the contractor's screen: PaymentFormat, in the
/// feature's shared/.
abstract final class ClientPaymentFormat {
  /// «1500» or «1500.50»: the amount as a bank app's field takes it, in
  /// Latin digits, with no currency and no thousands separator.
  static String plainAmount(Money money) {
    final riyals = money.halalas ~/ 100;
    final halalas = money.halalas % 100;
    return halalas == 0
        ? '$riyals'
        : '$riyals.${halalas.toString().padLeft(2, '0')}';
  }
}
