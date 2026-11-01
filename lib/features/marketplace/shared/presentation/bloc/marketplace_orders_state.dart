part of 'marketplace_orders_bloc.dart';

enum MarketplaceOrdersStatus { initial, loading, success, failure }

final class MarketplaceOrdersState {
  const MarketplaceOrdersState({
    this.status = MarketplaceOrdersStatus.initial,
    this.orders = const MyOrders(),
    this.filter,
    this.failure,
    this.refreshFailure,
  });

  final MarketplaceOrdersStatus status;
  final MyOrders orders;

  /// The selected chip; null is «الكل».
  final OrderStatus? filter;

  /// Why the list couldn't load the first time.
  final Failure? failure;

  /// Why a refresh failed while the list was on screen.
  final Failure? refreshFailure;

  /// The list has been on screen at least once.
  bool get hasLoaded =>
      status == MarketplaceOrdersStatus.success ||
      (status == MarketplaceOrdersStatus.loading && !orders.isEmpty);

  MarketplaceOrdersState copyWith({
    MarketplaceOrdersStatus? status,
    MyOrders? orders,
    OrderStatus? Function()? filter,
    Failure? Function()? failure,
    Failure? Function()? refreshFailure,
  }) {
    return MarketplaceOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      filter: filter == null ? this.filter : filter(),
      failure: failure == null ? this.failure : failure(),
      refreshFailure: refreshFailure == null
          ? this.refreshFailure
          : refreshFailure(),
    );
  }
}
