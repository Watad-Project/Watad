import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_check.dart';
import 'package:watad/features/marketplace/shared/domain/entities/payment_brand.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/check_card_use_case.dart';

void main() {
  // The 1st of November 2026.
  final checkCard = CheckCardUseCase(now: () => DateTime(2026, 11, 1));

  Future<CardCheck> check({
    PaymentMethod method = PaymentMethod.creditCard,
    String number = '4111 1111 1111 1111',
    String expiry = '12/28',
    String cvv = '123',
    String name = 'KHALID ALMUTAIRI',
  }) async => switch (await checkCard((
    method: method,
    number: number,
    expiry: expiry,
    cvv: cvv,
    name: name,
  ))) {
    Success(:final data) => data,
    Failed() => throw StateError('expected a check'),
  };

  group('Luhn', () {
    test('the test cards pass', () {
      expect(CheckCardUseCase.passesLuhn('4111111111111111'), isTrue);
      expect(CheckCardUseCase.passesLuhn('5555555555554444'), isTrue);
      expect(CheckCardUseCase.passesLuhn('4000000000000002'), isTrue);
    });

    test('one wrong digit fails', () {
      expect(CheckCardUseCase.passesLuhn('4111111111111112'), isFalse);
      expect(CheckCardUseCase.passesLuhn('5555555555554445'), isFalse);
    });
  });

  test('a good Visa gives only the brand and the last 4 digits', () async {
    final result = await check();

    expect(result.payment?.brand, PaymentBrand.visa);
    expect(result.payment?.last4, '1111');
    expect(result.declines, isFalse);
  });

  test('Mastercard by 51–55 and by 2221–2720', () async {
    expect(
      (await check(number: '5555 5555 5555 4444')).payment?.brand,
      PaymentBrand.mastercard,
    );
    expect(
      PaymentBrand.creditCardOf('2221000000000009'),
      PaymentBrand.mastercard,
    );
    expect(
      PaymentBrand.creditCardOf('2720990000000007'),
      PaymentBrand.mastercard,
    );
    expect(PaymentBrand.creditCardOf('2721000000000000'), isNull);
  });

  test('another network is refused as a credit card', () async {
    // A Luhn-valid number that is neither Visa nor Mastercard.
    final result = await check(number: '6011 1111 1111 1117');

    expect(result.payment, isNull);
    expect(result.numberError, 'marketplace.payment.error_brand');
  });

  test('mada sends the brand mada', () async {
    final result = await check(
      method: PaymentMethod.mada,
      number: '5555 5555 5555 4444',
    );

    expect(result.payment?.brand, PaymentBrand.mada);
    expect(result.payment?.last4, '4444');
  });

  test('a wrong digit or a short number is refused', () async {
    expect(
      (await check(number: '4111 1111 1111 1112')).numberError,
      'marketplace.payment.error_number',
    );
    expect(
      (await check(number: '4111 1111')).numberError,
      'marketplace.payment.error_number',
    );
  });

  test('only 4000 0000 0000 0002 declines', () async {
    expect((await check(number: '4000 0000 0000 0002')).declines, isTrue);
    expect((await check(number: '4111 1111 1111 1111')).declines, isFalse);
    expect((await check(number: '5555 5555 5555 4444')).declines, isFalse);
  });

  test('expiry: this month and next year pass, last month fails', () async {
    expect((await check(expiry: '11/26')).expiryError, isNull);
    expect((await check(expiry: '01/27')).expiryError, isNull);
    expect(
      (await check(expiry: '10/26')).expiryError,
      'marketplace.payment.error_expiry',
    );
    expect(
      (await check(expiry: '13/27')).expiryError,
      'marketplace.payment.error_expiry',
    );
  });

  test('CVV of 3 digits and a name of 2 characters', () async {
    final result = await check(cvv: '12', name: ' K ');

    expect(result.payment, isNull);
    expect(result.cvvError, 'marketplace.payment.error_cvv');
    expect(result.nameError, 'marketplace.payment.error_name');
    expect(result.numberError, isNull);
  });

  test('Apple Pay and STC Pay are not checked as cards', () async {
    final result = await checkCard((
      method: PaymentMethod.applePay,
      number: '',
      expiry: '',
      cvv: '',
      name: '',
    ));

    expect(result, isA<Failed<CardCheck>>());
  });
}
