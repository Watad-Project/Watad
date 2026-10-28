import 'dart:math';

/// How the payments screens write an IBAN: the client's bank transfer
/// (GRA-52) and the contractor's bank details (GRA-64).
abstract final class PaymentFormat {
  /// «SA03 8000 0000 6080 1016 7519»: in groups of four, to read it out.
  static String iban(String iban) => [
    for (var i = 0; i < iban.length; i += 4)
      iban.substring(i, min(i + 4, iban.length)),
  ].join(' ');
}
