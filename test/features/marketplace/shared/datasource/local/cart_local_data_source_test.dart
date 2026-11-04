import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/datasource/local/cart_local_data_source.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';

void main() {
  const cement = CartLine(
    itemId: 'i-cement',
    quantity: 2,
    priceWhenAdded: Money.halalas(4500),
  );
  const steel = CartLine(
    itemId: 'i-steel',
    quantity: 1,
    priceWhenAdded: Money.halalas(250000),
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a new data source reads back what an earlier one saved', () async {
    await const CartLocalDataSourceImpl(_userA).saveLines([cement, steel]);

    // Like the app after a restart: a fresh instance, the same storage.
    final lines = await const CartLocalDataSourceImpl(_userA).getLines();

    expect(lines.map((line) => line.itemId), ['i-cement', 'i-steel']);
    expect(lines.first.quantity, 2);
    expect(lines.first.priceWhenAdded, const Money.halalas(4500));
  });

  test('each user has their own cart', () async {
    await const CartLocalDataSourceImpl(_userA).saveLines([cement]);

    expect(await const CartLocalDataSourceImpl(_userB).getLines(), isEmpty);

    await const CartLocalDataSourceImpl(_userB).saveLines([steel]);
    final a = await const CartLocalDataSourceImpl(_userA).getLines();
    final b = await const CartLocalDataSourceImpl(_userB).getLines();
    expect(a.single.itemId, 'i-cement');
    expect(b.single.itemId, 'i-steel');
  });

  test('stores only ids, quantities and prices under the user key', () async {
    await const CartLocalDataSourceImpl(_userA).saveLines([cement]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'marketplace_cart.u-a'});
    expect(jsonDecode(prefs.getString('marketplace_cart.u-a')!), {
      'v': 1,
      'lines': [
        {'item_id': 'i-cement', 'quantity': 2, 'price_halalas': 4500},
      ],
    });
  });

  test('saving an empty cart removes it', () async {
    await const CartLocalDataSourceImpl(_userA).saveLines([cement]);
    await const CartLocalDataSourceImpl(_userA).saveLines(const []);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });

  test('signed out: nothing to read, and saving is refused', () async {
    const source = CartLocalDataSourceImpl(_signedOut);

    expect(await source.getLines(), isEmpty);
    expect(() => source.saveLines([cement]), throwsA(isA<AuthException>()));
  });
}

String? _userA() => 'u-a';
String? _userB() => 'u-b';
String? _signedOut() => null;
