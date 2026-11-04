import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/payment_brand.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/check_card_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/pay_order_use_case.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/payment_bloc.dart';

import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository orders;
  final orderId = fakeOrder().id;

  PaymentBloc buildBloc() => PaymentBloc(
    GetOrderUseCase(orders),
    CheckCardUseCase(now: () => DateTime(2026, 11, 1)),
    PayOrderUseCase(orders),
    processingDelay: Duration.zero,
  );

  Future<PaymentState> settled(PaymentBloc bloc, PaymentPageStatus status) =>
      bloc.stream.firstWhere((s) => s.status == status);

  setUp(() => orders = FakeOrdersRepository()..orders[orderId] = fakeOrder());

  test('a good card: processing, then paid', () async {
    final bloc = buildBloc()..add(PaymentStarted(orderId));
    await settled(bloc, PaymentPageStatus.ready);

    final states = <PaymentState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(
      const PaymentCardSubmitted(
        number: '4111 1111 1111 1111',
        expiry: '12/28',
        cvv: '737',
        name: 'KHALID ALMUTAIRI',
      ),
    );
    await settled(bloc, PaymentPageStatus.paid);
    await sub.cancel();

    expect(states.map((s) => s.status), [
      PaymentPageStatus.processing,
      PaymentPageStatus.paid,
    ]);
    expect(orders.payments.single.succeed, isTrue);
    await bloc.close();
  });

  test(
    'the full number and the CVV never reach a state or the repository',
    () async {
      const number = '4111111111111111';
      const cvv = '737';
      final bloc = buildBloc()..add(PaymentStarted(orderId));
      await settled(bloc, PaymentPageStatus.ready);

      final states = <PaymentState>[bloc.state];
      final sub = bloc.stream.listen(states.add);
      bloc.add(
        const PaymentCardSubmitted(
          number: '4111 1111 1111 1111',
          expiry: '12/28',
          cvv: cvv,
          name: 'KHALID ALMUTAIRI',
        ),
      );
      await settled(bloc, PaymentPageStatus.paid);
      await sub.cancel();

      // The repository gets the brand and last 4 digits, and nothing else.
      final sent = orders.payments.single;
      expect(sent.payment.brand, PaymentBrand.visa);
      expect(sent.payment.last4, '1111');
      expect(sent.orderId, orderId);

      for (final state in states) {
        final texts = [
          state.orderId,
          state.cardCheck?.payment?.last4,
          state.cardCheck?.numberError,
          state.cardCheck?.expiryError,
          state.cardCheck?.cvvError,
          state.cardCheck?.nameError,
          state.failure?.messageKey,
          state.order?.cardLast4,
        ].whereType<String>();
        for (final text in texts) {
          expect(text, isNot(contains(number)));
          expect(text, isNot(contains('4111 1111 1111 1111')));
          expect(text, isNot(equals(cvv)));
        }
      }
      await bloc.close();
    },
  );

  test('only 4000 0000 0000 0002 is sent as failed, and declines', () async {
    final bloc = buildBloc()..add(PaymentStarted(orderId));
    await settled(bloc, PaymentPageStatus.ready);

    bloc.add(
      const PaymentCardSubmitted(
        number: '4000 0000 0000 0002',
        expiry: '12/28',
        cvv: '123',
        name: 'KHALID',
      ),
    );
    await settled(bloc, PaymentPageStatus.declined);
    expect(orders.payments.single.succeed, isFalse);
    expect(orders.payments.single.payment.last4, '0002');
    // Still unpaid, so «حاول مرة أخرى» shows the form again.
    expect(orders.orders[orderId]?.status, OrderStatus.pendingPayment);

    bloc.add(const PaymentRetried());
    await settled(bloc, PaymentPageStatus.ready);
    await bloc.close();
  });

  test(
    'a wrong field keeps the form, with its error, and sends nothing',
    () async {
      final bloc = buildBloc()..add(PaymentStarted(orderId));
      await settled(bloc, PaymentPageStatus.ready);

      bloc.add(
        const PaymentCardSubmitted(
          number: '4111 1111 1111 1112',
          expiry: '10/26',
          cvv: '1',
          name: 'K',
        ),
      );
      final state = await bloc.stream.firstWhere((s) => s.cardCheck != null);
      expect(state.status, PaymentPageStatus.ready);
      expect(state.cardCheck?.numberError, 'marketplace.payment.error_number');
      expect(state.cardCheck?.expiryError, 'marketplace.payment.error_expiry');
      expect(orders.payments, isEmpty);
      await bloc.close();
    },
  );

  test('Apple Pay sends its name and 0000', () async {
    orders.orders[orderId] = fakeOrder(method: PaymentMethod.applePay);
    final bloc = buildBloc()..add(PaymentStarted(orderId));
    await settled(bloc, PaymentPageStatus.ready);

    bloc.add(const PaymentWalletConfirmed());
    await settled(bloc, PaymentPageStatus.paid);
    expect(orders.payments.single.payment.brand.value, 'Apple Pay');
    expect(orders.payments.single.payment.last4, '0000');
    await bloc.close();
  });

  test('a paid order is not payable', () async {
    orders.orders[orderId] = fakeOrder(status: OrderStatus.paid);
    final bloc = buildBloc()..add(PaymentStarted(orderId));

    await settled(bloc, PaymentPageStatus.notPayable);
    await bloc.close();
  });

  test('any other error while paying is a failure, not a decline', () async {
    orders.paymentResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(PaymentStarted(orderId));
    await settled(bloc, PaymentPageStatus.ready);

    bloc.add(const PaymentWalletConfirmed());
    // A card order: the wallet event does nothing, so send a card.
    bloc.add(
      const PaymentCardSubmitted(
        number: '4111 1111 1111 1111',
        expiry: '12/28',
        cvv: '123',
        name: 'KHALID',
      ),
    );
    final state = await settled(bloc, PaymentPageStatus.payFailure);
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('an order that cannot load is a load failure', () async {
    final bloc = buildBloc()..add(const PaymentStarted('missing'));

    final state = await settled(bloc, PaymentPageStatus.loadFailure);
    expect(state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });
}
