part of 'marketplace_order_details_bloc.dart';

sealed class MarketplaceOrderDetailsEvent {
  const MarketplaceOrderDetailsEvent();
}

/// The page opened ([orderId]), came back from the payment, was pulled, or
/// retry (the same order: no id).
final class MarketplaceOrderDetailsFetched
    extends MarketplaceOrderDetailsEvent {
  const MarketplaceOrderDetailsFetched([this.orderId]);

  final String? orderId;
}

/// «إلغاء الطلب», after the confirmation.
final class MarketplaceOrderCancelled extends MarketplaceOrderDetailsEvent {
  const MarketplaceOrderCancelled();
}

/// «تم الاستلام», after the confirmation.
final class MarketplaceOrderDeliveryConfirmed
    extends MarketplaceOrderDetailsEvent {
  const MarketplaceOrderDeliveryConfirmed();
}

/// «تم الشحن», after the confirmation.
final class MarketplaceOrderShipped extends MarketplaceOrderDetailsEvent {
  const MarketplaceOrderShipped();
}
