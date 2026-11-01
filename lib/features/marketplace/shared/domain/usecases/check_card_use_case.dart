import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_check.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';
import 'package:watad/features/marketplace/shared/domain/entities/payment_brand.dart';

/// The card form of the demo payment, checked on the phone: 16 digits that
/// pass the Luhn checksum, an expiry `MM/YY` from this month on, a 3-digit
/// CVV and a name of 2 characters or more. «بطاقة ائتمانية» takes Visa and
/// Mastercard; «مدى» sends the brand `mada`.
///
/// Only the brand and the last 4 digits come out of it ([CardPayment]): the
/// full number and the CVV stay in the form.
class CheckCardUseCase
    implements
        UseCase<
          CardCheck,
          ({
            PaymentMethod method,
            String number,
            String expiry,
            String cvv,
            String name,
          })
        > {
  CheckCardUseCase({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// The demo card that always fails, to show the failure screen.
  static const String declineCardNumber = '4000000000000002';

  @override
  Future<Result<CardCheck>> call(
    ({
      PaymentMethod method,
      String number,
      String expiry,
      String cvv,
      String name,
    })
    params,
  ) async {
    if (params.method != PaymentMethod.mada &&
        params.method != PaymentMethod.creditCard) {
      return const Failed(
        ValidationFailure('marketplace.payment.error_method'),
      );
    }
    final digits = params.number.replaceAll(' ', '');
    final brand = params.method == PaymentMethod.mada
        ? PaymentBrand.mada
        : PaymentBrand.creditCardOf(digits);

    final numberError =
        !RegExp(r'^\d{16}$').hasMatch(digits) || !passesLuhn(digits)
        ? 'marketplace.payment.error_number'
        : brand == null
        ? 'marketplace.payment.error_brand'
        : null;
    final expiryError = _isFuture(params.expiry)
        ? null
        : 'marketplace.payment.error_expiry';
    final cvvError = RegExp(r'^\d{3}$').hasMatch(params.cvv.trim())
        ? null
        : 'marketplace.payment.error_cvv';
    final nameError = params.name.trim().length >= 2
        ? null
        : 'marketplace.payment.error_name';

    final isValid =
        numberError == null &&
        expiryError == null &&
        cvvError == null &&
        nameError == null;
    return Success(
      CardCheck(
        payment: isValid
            ? CardPayment(brand: brand!, last4: digits.substring(12))
            : null,
        declines: isValid && digits == declineCardNumber,
        numberError: numberError,
        expiryError: expiryError,
        cvvError: cvvError,
        nameError: nameError,
      ),
    );
  }

  /// The Luhn checksum of card numbers: from the right, every second digit
  /// is doubled (minus 9 above 9), and the sum ends in 0.
  static bool passesLuhn(String digits) {
    var sum = 0;
    var isSecond = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var digit = digits.codeUnitAt(i) - 0x30;
      if (isSecond) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      isSecond = !isSecond;
    }
    return digits.isNotEmpty && sum % 10 == 0;
  }

  /// `MM/YY` (or `MMYY`) in this month or later, at most 20 years ahead.
  bool _isFuture(String expiry) {
    final match = RegExp(r'^(\d{2})/?(\d{2})$').firstMatch(expiry.trim());
    if (match == null) return false;
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return false;
    final now = _now();
    if (year > now.year + 20) return false;
    return year > now.year || (year == now.year && month >= now.month);
  }
}
