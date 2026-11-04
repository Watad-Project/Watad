import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_address.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';

/// A marketplace order the signed-in user bought or sold (`v_my_orders`).
class MarketplaceOrder {
  const MarketplaceOrder({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.total,
    required this.myRole,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.lineCount,
    required this.unitCount,
    required this.createdAt,
    this.cardBrand,
    this.cardLast4,
    this.paidAt,
    this.buyerAvatarUrl,
    this.sellerAvatarUrl,
    this.canReview = false,
    this.deliveryAddress,
  });

  final String id;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final Money total;
  final OrderRole myRole;
  final String buyerId;
  final String buyerName;
  final String? buyerAvatarUrl;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;

  /// Different items, and the units of all of them.
  final int lineCount;
  final int unitCount;

  final DateTime createdAt;

  /// Set once paid: the brand (`Visa`, `mada`, `Apple Pay`, …) and, for a
  /// card, its last 4 digits.
  final String? cardBrand;
  final String? cardLast4;
  final DateTime? paidAt;

  /// Delivered, and I haven't reviewed the other party yet.
  final bool canReview;

  /// Null on orders from before migration 82.
  final OrderAddress? deliveryAddress;

  /// The short order number people read and say: the id's first 8
  /// characters.
  String get number => id.replaceAll('-', '').substring(0, 8).toUpperCase();

  /// «مدى» and «بطاقة ائتمانية»: a card with a number and last 4 digits.
  bool get isCardMethod =>
      paymentMethod == PaymentMethod.mada ||
      paymentMethod == PaymentMethod.creditCard;

  /// I bought it and it still waits for a (card or wallet) payment.
  bool get isPayableByMe =>
      myRole == OrderRole.buyer &&
      status == OrderStatus.pendingPayment &&
      paymentMethod != PaymentMethod.bankTransfer;
}
