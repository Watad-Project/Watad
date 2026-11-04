import 'package:watad/core/enums/order_status.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';

/// What I can do with an order now, by its status and my side of it. The
/// server checks the same rules (`cancel_order()`, `mark_order_shipped()`,
/// `confirm_order_delivered()`); the page shows only what it would accept.
class OrderActions {
  const OrderActions({
    this.canPay = false,
    this.canShip = false,
    this.canCancel = false,
    this.canConfirmDelivery = false,
    this.canReview = false,
  });

  factory OrderActions.of(MarketplaceOrder order) {
    final isUnpaid = order.status == OrderStatus.pendingPayment;
    final canReview = order.status == OrderStatus.delivered && order.canReview;
    if (order.myRole == OrderRole.seller) {
      // `cancel_order()` lets the seller cancel an unpaid order too.
      return OrderActions(
        canShip: order.status == OrderStatus.paid,
        canCancel: isUnpaid,
        canReview: canReview,
      );
    }
    return OrderActions(
      canPay: order.isPayableByMe,
      canCancel: isUnpaid,
      canConfirmDelivery:
          order.status == OrderStatus.paid ||
          order.status == OrderStatus.shipped,
      canReview: canReview,
    );
  }

  /// «ادفع الآن»: unpaid, by card or wallet.
  final bool canPay;

  /// «تم الشحن»: paid, by the seller.
  final bool canShip;

  /// «إلغاء الطلب»: only while unpaid, by the buyer or the seller; a paid
  /// order needs a refund.
  final bool canCancel;

  /// «تم الاستلام»: paid or shipped, by the buyer.
  final bool canConfirmDelivery;

  /// «تقييم البائع» / «تقييم المشتري»: delivered, and not reviewed yet.
  final bool canReview;
}
