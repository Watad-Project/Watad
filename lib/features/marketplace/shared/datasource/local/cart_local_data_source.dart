import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/marketplace/shared/datasource/models/cart_line_model.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';

abstract interface class CartLocalDataSource {
  Future<List<CartLineModel>> getLines();

  Future<void> saveLines(List<CartLine> lines);
}

/// The cart on the phone, one per signed-in user, under
/// `marketplace_cart.<user id>`:
///
/// ```json
/// {"v": 1, "lines": [{"item_id": "…", "quantity": 2, "price_halalas": 4500}]}
/// ```
///
/// Only ids, quantities and the price when added: names, photos and the
/// seller are read from the server again.
class CartLocalDataSourceImpl implements CartLocalDataSource {
  const CartLocalDataSourceImpl(this._currentUserId);

  /// The signed-in user's id, or null when nobody is signed in.
  final String? Function() _currentUserId;

  static const String keyPrefix = 'marketplace_cart.';
  static const int _version = 1;

  @override
  Future<List<CartLineModel>> getLines() async {
    final userId = _currentUserId();
    if (userId == null) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$keyPrefix$userId');
    if (raw == null) return const [];
    final stored = jsonDecode(raw) as Map<String, dynamic>;
    if (stored['v'] != _version) return const [];
    return [
      for (final line in stored['lines'] as List<dynamic>)
        CartLineModel.fromJson(line as Map<String, dynamic>),
    ].where((line) => line.quantity > 0).toList();
  }

  @override
  Future<void> saveLines(List<CartLine> lines) async {
    final userId = _currentUserId();
    if (userId == null) {
      throw const AuthException('Sign in to use the cart');
    }
    final prefs = await SharedPreferences.getInstance();
    final key = '$keyPrefix$userId';
    if (lines.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(
      key,
      jsonEncode({
        'v': _version,
        'lines': [
          for (final line in lines)
            {
              'item_id': line.itemId,
              'quantity': line.quantity,
              'price_halalas': line.priceWhenAdded.halalas,
            },
        ],
      }),
    );
  }
}
