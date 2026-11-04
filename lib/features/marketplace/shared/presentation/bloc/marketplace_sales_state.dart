part of 'marketplace_sales_bloc.dart';

enum MarketplaceSalesStatus { initial, loading, success, failure }

final class MarketplaceSalesState {
  const MarketplaceSalesState({
    this.status = MarketplaceSalesStatus.initial,
    this.orders = const MyOrders(),
    this.filter,
    this.failure,
    this.refreshFailure,
  });

  final MarketplaceSalesStatus status;
  final MyOrders orders;

  /// The selected chip; null is «الكل».
  final OrderStatus? filter;

  /// Why the list couldn't load the first time.
  final Failure? failure;

  /// Why a refresh failed while the list was on screen.
  final Failure? refreshFailure;

  /// The list has been on screen at least once.
  bool get hasLoaded =>
      status == MarketplaceSalesStatus.success ||
      (status == MarketplaceSalesStatus.loading && !orders.isEmpty);

  MarketplaceSalesState copyWith({
    MarketplaceSalesStatus? status,
    MyOrders? orders,
    OrderStatus? Function()? filter,
    Failure? Function()? failure,
    Failure? Function()? refreshFailure,
  }) {
    return MarketplaceSalesState(
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
