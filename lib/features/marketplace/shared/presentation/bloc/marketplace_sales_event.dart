part of 'marketplace_sales_bloc.dart';

sealed class MarketplaceSalesEvent {
  const MarketplaceSalesEvent();
}

/// The page opened, came back from an order, was pulled, or retry.
final class MarketplaceSalesFetched extends MarketplaceSalesEvent {
  const MarketplaceSalesFetched();
}

/// A filter chip; null is «الكل».
final class MarketplaceSalesFilterSelected extends MarketplaceSalesEvent {
  const MarketplaceSalesFilterSelected(this.status);

  final OrderStatus? status;
}
