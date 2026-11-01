import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_details.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_order_details_use_case.dart';

import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeOrdersRepository orders;
  late GetOrderDetailsUseCase getDetails;
  final orderId = fakeOrder().id;

  setUp(() {
    orders = FakeOrdersRepository()..orders[orderId] = fakeOrder();
    getDetails = GetOrderDetailsUseCase(orders);
  });

  test('the order, its products and its timeline', () async {
    final result = await getDetails(orderId);

    final details = (result as Success<OrderDetails>).data;
    expect(details.order.id, orderId);
    expect(details.lines, fakeOrderLines);
    expect(details.history.single.newStatus, OrderStatus.pendingPayment);
    expect(details.actions.canPay, isTrue);
  });

  test('the seller reads the same order', () async {
    orders.orders[orderId] = fakeOrder(role: OrderRole.seller);

    final result = await getDetails(orderId);

    final details = (result as Success<OrderDetails>).data;
    expect(details.order.myRole, OrderRole.seller);
    expect(details.actions.canCancel, isFalse);
  });

  test('an order I cannot see is not found', () async {
    expect(
      await getDetails('missing'),
      isA<Failed<OrderDetails>>().having(
        (f) => f.failure,
        'failure',
        isA<NotFoundFailure>(),
      ),
    );
  });

  test('any part that fails fails the page', () async {
    orders.historyResult = const Failed(NetworkFailure());

    final result = await getDetails(orderId);

    expect(
      result,
      isA<Failed<OrderDetails>>().having(
        (f) => f.failure,
        'failure',
        isA<NetworkFailure>(),
      ),
    );
  });
}
