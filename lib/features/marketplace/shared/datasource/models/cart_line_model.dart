import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';

class CartLineModel extends CartLine {
  const CartLineModel({
    required super.itemId,
    required super.quantity,
    required super.priceWhenAdded,
  });

  /// Maps one stored line of [CartLocalDataSourceImpl]:
  /// `{"item_id": "…", "quantity": 2, "price_halalas": 4500}`.
  factory CartLineModel.fromJson(Map<String, dynamic> json) {
    return CartLineModel(
      itemId: json['item_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      priceWhenAdded: Money.halalas((json['price_halalas'] as num).toInt()),
    );
  }
}
