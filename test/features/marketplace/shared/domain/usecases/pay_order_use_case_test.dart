import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';
import 'package:watad/features/marketplace/shared/domain/entities/payment_brand.dart';
import 'package:watad/features/marketplace/shared/domain/entities/payment_outcome.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/pay_order_use_case.dart';

import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository orders;
  late PayOrderUseCase pay;
  final orderId = fakeOrder().id;
  const visa = CardPayment(brand: PaymentBrand.visa, last4: '1111');

  setUp(() {
    orders = FakeOrdersRepository()..orders[orderId] = fakeOrder();
    pay = PayOrderUseCase(orders);
  });

  test('a good card pays the order, sending only brand and last 4', () async {
    final result = await pay((orderId: orderId, payment: visa, succeed: true));

    expect((result as Success<PaymentOutcome>).data, PaymentOutcome.paid);
    final sent = orders.payments.single;
    expect(sent.payment.brand.value, 'Visa');
    expect(sent.payment.last4, '1111');
    expect(sent.succeed, isTrue);
  });

  test('sent as failed, the server refusal is a decline', () async {
    final result = await pay((orderId: orderId, payment: visa, succeed: false));

    expect((result as Success<PaymentOutcome>).data, PaymentOutcome.declined);
  });

  test('a server error on a good card stays a failure', () async {
    orders.paymentResult = const Failed(ServerFailure());

    final result = await pay((orderId: orderId, payment: visa, succeed: true));

    expect((result as Failed<PaymentOutcome>).failure, isA<ServerFailure>());
  });

  test('a lost connection is never taken for a decline', () async {
    orders.paymentResult = const Failed(NetworkFailure());

    final result = await pay((orderId: orderId, payment: visa, succeed: false));

    expect((result as Failed<PaymentOutcome>).failure, isA<NetworkFailure>());
  });

  test('a wallet sends its name and 0000', () async {
    await pay((
      orderId: orderId,
      payment: const CardPayment.wallet(PaymentBrand.applePay),
      succeed: true,
    ));

    expect(orders.payments.single.payment.brand.value, 'Apple Pay');
    expect(orders.payments.single.payment.last4, '0000');
  });
}
