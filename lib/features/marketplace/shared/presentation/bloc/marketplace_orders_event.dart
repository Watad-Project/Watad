part of 'marketplace_orders_bloc.dart';

sealed class MarketplaceOrdersEvent {
  const MarketplaceOrdersEvent();
}

/// The page opened, came back from an order, was pulled, or retry.
final class MarketplaceOrdersFetched extends MarketplaceOrdersEvent {
  const MarketplaceOrdersFetched();
}

/// A filter chip; null is «الكل».
final class MarketplaceOrdersFilterSelected extends MarketplaceOrdersEvent {
  const MarketplaceOrdersFilterSelected(this.status);

  final OrderStatus? status;
}
