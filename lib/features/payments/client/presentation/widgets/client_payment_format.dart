import 'dart:math';

import 'package:watad/core/utils/money.dart';

/// How the bank transfer screen writes an IBAN and an amount (GRA-52).
abstract final class ClientPaymentFormat {
  /// «SA03 8000 0000 6080 1016 7519»: in groups of four, to read it out.
  static String iban(String iban) => [
    for (var i = 0; i < iban.length; i += 4)
      iban.substring(i, min(i + 4, iban.length)),
  ].join(' ');

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
