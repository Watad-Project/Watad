import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_problem.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_review.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/review_checkout_use_case.dart';

import '../../../../../helpers/fake_cart_repository.dart';
import '../../../../../helpers/fake_marketplace_repository.dart';
import '../../../../../helpers/fake_orders_repository.dart';

void main() {
  late FakeMarketplaceRepository items;
  late FakeCartRepository cart;
  late FakeOrdersRepository orders;
  late ReviewCheckoutUseCase review;

  setUp(() {
    items = FakeMarketplaceRepository()..items = [fakeSteelItem, fakeTilesItem];
    cart = FakeCartRepository([
      const CartLine(
        itemId: 'i-steel',
        quantity: 12,
        priceWhenAdded: Money.halalas(240000),
      ),
      const CartLine(
        itemId: 'i-tiles',
        quantity: 2,
        priceWhenAdded: Money.halalas(6500),
      ),
    ]);
    orders = FakeOrdersRepository();
    review = ReviewCheckoutUseCase(cart, items, orders);
  });

  Future<CheckoutReview> reviewOf(String sellerId) async =>
      switch (await review(sellerId)) {
        Success(:final data) => data,
        Failed() => throw StateError('expected a review'),
      };

  test("one seller's lines at the current price, cut to the stock", () async {
    final result = await reviewOf('u-seller');

    expect(result.problem, isNull);
    expect(result.sellerName, 'سارة العتيبي');
    final entry = result.entries.single;
    expect(entry.line.itemId, 'i-steel');
    expect(entry.line.quantity, 10);
    expect(entry.line.priceWhenAdded, const Money.halalas(250000));
    expect(result.hasChanges, isTrue);
    expect(result.total, const Money.halalas(2500000));
    expect(result.addresses.single.id, 'a-home');
    // The cart now holds what the buyer is shown.
    expect(cart.lines.first.quantity, 10);
  });

  test('5 unpaid orders stop the checkout', () async {
    orders.unpaidCount = 5;

    final result = await reviewOf('u-seller');
    expect(result.problem, CheckoutProblem.tooManyUnpaidOrders);
    expect(result.unpaidOrderCount, 5);
  });

  test('more than 50 lines stop the checkout', () async {
    final many = [for (var i = 0; i < 51; i++) fakeTilesItemWith('i-tile-$i')];
    items.items = many;
    cart.lines = [
      for (final item in many)
        CartLine(itemId: item.id, quantity: 1, priceWhenAdded: item.price),
    ];

    final result = await reviewOf('u-tiles');
    expect(result.entries, hasLength(51));
    expect(result.problem, CheckoutProblem.tooManyLines);
  });

  test('my own item in the cart stops the checkout', () async {
    cart.lines = [
      const CartLine(
        itemId: 'i-cement',
        quantity: 1,
        priceWhenAdded: Money.halalas(4500),
      ),
    ];

    final result = await reviewOf('u-business');
    expect(result.problem, CheckoutProblem.ownItem);
  });

  test('nothing of that seller is empty', () async {
    final result = await reviewOf('u-nobody');
    expect(result.problem, CheckoutProblem.empty);
  });
}

/// [fakeTilesItem] under another id: one more item of the same seller.
MarketplaceItem fakeTilesItemWith(String id) => MarketplaceItem(
  id: id,
  name: fakeTilesItem.name,
  price: fakeTilesItem.price,
  stockQuantity: fakeTilesItem.stockQuantity,
  inStock: true,
  isActive: true,
  category: fakeTilesItem.category,
  createdAt: fakeTilesItem.createdAt,
  updatedAt: fakeTilesItem.updatedAt,
  sellerId: fakeTilesItem.sellerId,
  sellerName: fakeTilesItem.sellerName,
);
