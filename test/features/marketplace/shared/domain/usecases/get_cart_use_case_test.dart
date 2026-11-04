import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_cart_use_case.dart';

import '../../../../../helpers/fake_cart_repository.dart';
import '../../../../../helpers/fake_marketplace_repository.dart';

void main() {
  late FakeMarketplaceRepository items;
  late FakeCartRepository cart;
  late GetCartUseCase getCart;

  setUp(() {
    items = FakeMarketplaceRepository()
      ..items = [fakeSteelItem, fakeTilesItem, _soldOut];
    cart = FakeCartRepository();
    getCart = GetCartUseCase(cart, items);
  });

  CartLine line(String id, int quantity, int halalas) => CartLine(
    itemId: id,
    quantity: quantity,
    priceWhenAdded: Money.halalas(halalas),
  );

  Future<Cart> load() async => switch (await getCart()) {
    Success(:final data) => data,
    Failed() => throw StateError('expected a cart'),
  };

  test('groups the lines by seller, in the order they were added', () async {
    cart.lines = [line('i-tiles', 2, 6500), line('i-steel', 1, 250000)];

    final result = await load();

    expect(result.groups.map((g) => g.sellerId), ['u-tiles', 'u-seller']);
    expect(result.groups.first.total, const Money.halalas(13000));
    expect(result.hasChanges, isFalse);
    expect(cart.saved, isEmpty);
  });

  test('a gone, sold-out or own item is unavailable and not counted', () async {
    cart.lines = [
      line('i-gone', 1, 100),
      line('i-sold-out', 1, 3200),
      line('i-cement', 1, 4500),
      line('i-steel', 1, 250000),
    ];

    final result = await load();

    expect(result.unavailable.map((e) => e.line.itemId), [
      'i-gone',
      'i-sold-out',
      'i-cement',
    ]);
    expect(result.unavailable.first.item, isNull);
    expect(result.groups.single.total, const Money.halalas(250000));
  });

  test('a quantity above the stock is lowered and saved', () async {
    cart.lines = [line('i-steel', 15, 250000)];

    final result = await load();

    final entry = result.groups.single.entries.single;
    expect(entry.line.quantity, 10);
    expect(entry.previousQuantity, 15);
    expect(result.hasChanges, isTrue);
    expect(cart.lines.single.quantity, 10);
  });

  test('a new price is shown with the old one, and saved', () async {
    cart.lines = [line('i-steel', 1, 240000)];

    final result = await load();

    final entry = result.groups.single.entries.single;
    expect(entry.previousPrice, const Money.halalas(240000));
    expect(entry.subtotal, const Money.halalas(250000));
    expect(cart.lines.single.priceWhenAdded, const Money.halalas(250000));
  });

  test('an empty cart reads nothing from the server', () async {
    items.itemsByIdsResult = const Failed(NetworkFailure());

    expect((await load()).isEmpty, isTrue);
  });

  test('passes on a failure', () async {
    cart.lines = [line('i-steel', 1, 250000)];
    items.itemsByIdsResult = const Failed(NetworkFailure());

    expect(await getCart(), isA<Failed<Cart>>());
  });
}

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
  sellerId: 'u-tiles',
  sellerName: 'مؤسسة البلاط',
);
