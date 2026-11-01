import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_address.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';

class MarketplaceOrderModel extends MarketplaceOrder {
  const MarketplaceOrderModel({
    required super.id,
    required super.status,
    required super.paymentMethod,
    required super.total,
    required super.myRole,
    required super.buyerId,
    required super.buyerName,
    required super.sellerId,
    required super.sellerName,
    required super.lineCount,
    required super.unitCount,
    required super.createdAt,
    super.cardBrand,
    super.cardLast4,
    super.paidAt,
    super.buyerAvatarUrl,
    super.sellerAvatarUrl,
    super.canReview,
    super.deliveryAddress,
  });

  /// Maps a `v_my_orders` row, plus `buyer_avatar_url` and
  /// `seller_avatar_url` added by [OrdersRemoteDataSourceImpl].
  factory MarketplaceOrderModel.fromJson(Map<String, dynamic> json) {
    final paidAt = json['paid_at'] as String?;
    final address = json['delivery_address'] as Map<String, dynamic>?;
    final last4 = (json['card_last4'] as String?)?.trim();
    return MarketplaceOrderModel(
      id: json['id'] as String,
      status: OrderStatus.fromJson(json['status'] as String),
      paymentMethod: PaymentMethod.fromJson(json['payment_method'] as String),
      total: Money.fromJson(json['total_amount'] as num),
      myRole: json['my_role'] == 'seller' ? OrderRole.seller : OrderRole.buyer,
      buyerId: json['buyer_id'] as String,
      buyerName: json['buyer_name'] as String? ?? '',
      buyerAvatarUrl: json['buyer_avatar_url'] as String?,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String? ?? '',
      sellerAvatarUrl: json['seller_avatar_url'] as String?,
      lineCount: (json['line_count'] as num?)?.toInt() ?? 0,
      unitCount: (json['unit_count'] as num?)?.toInt() ?? 0,
      canReview: json['can_review'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      paidAt: paidAt == null ? null : DateTime.parse(paidAt),
      cardBrand: json['card_brand'] as String?,
      cardLast4: last4 == null || last4.isEmpty ? null : last4,
      deliveryAddress: address == null
          ? null
          : OrderAddress(
              name: address['name'] as String?,
              city: address['city'] as String?,
              district: address['district'] as String?,
              formattedAddress: address['formatted_address'] as String?,
            ),
    );
  }
}
