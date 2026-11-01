import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_addition.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/add_to_cart_use_case.dart';

import '../../../../../helpers/fake_cart_repository.dart';
import '../../../../../helpers/fake_marketplace_repository.dart';

void main() {
  late FakeCartRepository cart;
  late AddToCartUseCase addToCart;

  setUp(() {
    cart = FakeCartRepository();
    addToCart = AddToCartUseCase(cart);
  });

  String? errorOf(Result<CartAddition> result) => switch (result) {
    Failed(:final failure) => failure.messageKey,
    Success() => null,
  };

  test('adds a new line with the price shown now', () async {
    final result = await addToCart((item: fakeSteelItem, quantity: 2));

    expect(result, isA<Success<CartAddition>>());
    final line = cart.lines.single;
    expect(line.itemId, 'i-steel');
    expect(line.quantity, 2);
    expect(line.priceWhenAdded, fakeSteelItem.price);
  });

  test('adding the same item again adds to its line, in place', () async {
    cart.lines = [
      const CartLine(
        itemId: 'i-other',
        quantity: 1,
        priceWhenAdded: Money.halalas(100),
      ),
      const CartLine(
        itemId: 'i-steel',
        quantity: 3,
        priceWhenAdded: Money.halalas(240000),
      ),
    ];

    final result = await addToCart((item: fakeSteelItem, quantity: 4));

    expect(cart.lines.map((line) => line.itemId), ['i-other', 'i-steel']);
    expect(cart.lines.last.quantity, 7);
    // The line takes the price shown now.
    expect(cart.lines.last.priceWhenAdded, const Money.halalas(250000));
    expect((result as Success<CartAddition>).data.isCapped, isFalse);
  });

  test('the cart and the new quantity are cut to the stock', () async {
    cart.lines = [
      const CartLine(
        itemId: 'i-steel',
        quantity: 8,
        priceWhenAdded: Money.halalas(250000),
      ),
    ];

    final result = await addToCart((item: fakeSteelItem, quantity: 5));

    expect(cart.lines.single.quantity, 10);
    final addition = (result as Success<CartAddition>).data;
    expect(addition.quantityInCart, 10);
    expect(addition.isCapped, isTrue);
  });

  test('refuses my own item, an unavailable one, and a bad quantity', () async {
    expect(
      errorOf(await addToCart((item: fakeCementItem, quantity: 1))),
      'marketplace.item_details.error_own_item',
    );
    expect(
      errorOf(await addToCart((item: _soldOut, quantity: 1))),
      'marketplace.item_details.error_unavailable',
    );
    expect(
      errorOf(await addToCart((item: fakeSteelItem, quantity: 0))),
      'marketplace.item_details.error_quantity',
    );
    expect(
      errorOf(await addToCart((item: fakeSteelItem, quantity: 11))),
      'marketplace.item_details.error_quantity',
    );
    expect(cart.saved, isEmpty);
  });

  test('passes on a storage failure', () async {
    cart.saveResult = const Failed(UnknownFailure());

    final result = await addToCart((item: fakeSteelItem, quantity: 1));

    expect(errorOf(result), 'errors.unknown');
  });
}

/// Someone else's item with nothing left.
final MarketplaceItem _soldOut = MarketplaceItem(
  id: 'i-sold-out',
  name: 'بلاط',
  price: const Money.halalas(3200),
  stockQuantity: 0,
  inStock: false,
  isActive: true,
  category: MarketplaceCategory.flooringTiles,
  createdAt: DateTime.utc(2026, 10, 18),
  updatedAt: DateTime.utc(2026, 10, 18),
  sellerId: 'u-seller',
  sellerName: 'سارة العتيبي',
);
