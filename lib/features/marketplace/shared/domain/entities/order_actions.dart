import 'package:watad/core/enums/order_status.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';

/// What I can do with an order now, by its status and my side of it. The
/// server checks the same rules (`cancel_order()`,
/// `confirm_order_delivered()`); the page shows only what it would accept.
class OrderActions {
  const OrderActions({
    this.canPay = false,
    this.canCancel = false,
    this.canConfirmDelivery = false,
    this.canReview = false,
  });

  factory OrderActions.of(MarketplaceOrder order) {
    if (order.myRole == OrderRole.seller) {
      // The seller's actions (ship it) come with «مبيعاتي» (GRA-71).
      return const OrderActions();
    }
    final isUnpaid = order.status == OrderStatus.pendingPayment;
    return OrderActions(
      canPay: order.isPayableByMe,
      canCancel: isUnpaid,
      canConfirmDelivery:
          order.status == OrderStatus.paid ||
          order.status == OrderStatus.shipped,
      canReview: order.status == OrderStatus.delivered && order.canReview,
    );
  }

  /// «ادفع الآن»: unpaid, by card or wallet.
  final bool canPay;

  /// «إلغاء الطلب»: only while unpaid; a paid order needs a refund.
  final bool canCancel;

  /// «تم الاستلام»: paid or shipped, by the buyer.
  final bool canConfirmDelivery;

  /// «تقييم البائع»: delivered, and not reviewed yet.
  final bool canReview;
}
