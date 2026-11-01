import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_problem.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_request.dart';
import 'package:watad/features/marketplace/shared/domain/entities/placed_order.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/place_order_use_case.dart';

import '../../../../../helpers/fake_cart_repository.dart';
import '../../../../../helpers/fake_marketplace_repository.dart';
import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeMarketplaceRepository items;
  late FakeCartRepository cart;
  late FakeOrdersRepository orders;
  late PlaceOrderUseCase placeOrder;

  const steel = CartLine(
    itemId: 'i-steel',
    quantity: 2,
    priceWhenAdded: Money.halalas(250000),
  );
  const tiles = CartLine(
    itemId: 'i-tiles',
    quantity: 1,
    priceWhenAdded: Money.halalas(6500),
  );

  setUp(() {
    items = FakeMarketplaceRepository()..items = [fakeSteelItem, fakeTilesItem];
    cart = FakeCartRepository([steel, tiles]);
    orders = FakeOrdersRepository();
    placeOrder = PlaceOrderUseCase(cart, items, orders);
  });

  CheckoutRequest request(
    List<CartLine> lines, {
    String sellerId = 'u-seller',
    PaymentMethod method = PaymentMethod.mada,
  }) => CheckoutRequest(
    sellerId: sellerId,
    lines: lines,
    method: method,
    addressId: 'a-home',
  );

  String? errorOf(Result<PlacedOrder> result) => switch (result) {
    Failed(:final failure) => failure.messageKey,
    Success() => null,
  };

  test(
    'places the order and takes exactly its lines out of the cart',
    () async {
      final result = await placeOrder(request([steel]));

      final placed = (result as Success<PlacedOrder>).data;
      expect(placed.orderId, orders.nextOrderId);
      expect(placed.cartCleared, isTrue);
      expect(orders.checkouts.single.lines.single.itemId, 'i-steel');
      expect(cart.lines.map((l) => l.itemId), ['i-tiles']);
    },
  );

  test('items from two sellers are refused before checkout()', () async {
    final result = await placeOrder(request([steel, tiles]));

    expect(errorOf(result), CheckoutProblem.mixedSellers.messageKey);
    expect(orders.checkouts, isEmpty);
  });

  test('too little stock is refused before checkout()', () async {
    final result = await placeOrder(
      request([
        const CartLine(
          itemId: 'i-steel',
          quantity: 11,
          priceWhenAdded: Money.halalas(250000),
        ),
      ]),
    );

    expect(errorOf(result), CheckoutProblem.notEnoughStock.messageKey);
    expect(orders.checkouts, isEmpty);
  });

  test('a price changed since the page loaded is refused', () async {
    final result = await placeOrder(
      request([
        const CartLine(
          itemId: 'i-steel',
          quantity: 1,
          priceWhenAdded: Money.halalas(240000),
        ),
      ]),
    );

    expect(errorOf(result), CheckoutProblem.changed.messageKey);
  });

  test('my own item is refused', () async {
    final result = await placeOrder(
      request(sellerId: 'u-business', [
        const CartLine(
          itemId: 'i-cement',
          quantity: 1,
          priceWhenAdded: Money.halalas(4500),
        ),
      ]),
    );

    expect(errorOf(result), CheckoutProblem.ownItem.messageKey);
  });

  test('a hidden or deleted item is refused', () async {
    items.items = [fakeTilesItem];

    final result = await placeOrder(request([steel]));

    expect(errorOf(result), CheckoutProblem.unavailable.messageKey);
  });

  test('5 unpaid orders are refused', () async {
    orders.unpaidCount = 5;

    final result = await placeOrder(request([steel]));

    expect(errorOf(result), CheckoutProblem.tooManyUnpaidOrders.messageKey);
    expect(orders.checkouts, isEmpty);
  });

  test('more than 50 lines are refused', () async {
    final result = await placeOrder(request(List.filled(51, steel)));

    expect(errorOf(result), CheckoutProblem.tooManyLines.messageKey);
  });

  test('bank transfer is never offered', () async {
    final result = await placeOrder(
      request([steel], method: PaymentMethod.bankTransfer),
    );

    expect(errorOf(result), 'marketplace.checkout.error_method');
  });

  test("the server's own error stays a failure", () async {
    orders.checkoutResult = const Failed(ServerFailure());

    final result = await placeOrder(request([steel]));

    expect(errorOf(result), 'errors.server');
    expect(cart.lines, hasLength(2));
  });

  test('a cart that cannot be cleared still returns the order', () async {
    cart.saveResult = const Failed(UnknownFailure());

    final result = await placeOrder(request([steel]));

    final placed = (result as Success<PlacedOrder>).data;
    expect(placed.cartCleared, isFalse);
  });
}
