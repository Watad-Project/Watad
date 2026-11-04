part of 'marketplace_order_details_bloc.dart';

enum MarketplaceOrderDetailsStatus { initial, loading, success, failure }

/// The buyer's and seller's actions on the page.
enum OrderDetailsAction { cancel, confirmDelivery, ship }

final class MarketplaceOrderDetailsState {
  const MarketplaceOrderDetailsState({
    this.orderId,
    this.status = MarketplaceOrderDetailsStatus.initial,
    this.details,
    this.failure,
    this.pendingAction,
    this.doneAction,
    this.actionFailure,
  });

  final String? orderId;
  final MarketplaceOrderDetailsStatus status;
  final OrderDetails? details;

  /// Why the order couldn't load the first time.
  final Failure? failure;

  /// The action being sent; its button shows a spinner.
  final OrderDetailsAction? pendingAction;

  /// The action that just went through, for its snackbar.
  final OrderDetailsAction? doneAction;

  /// Why an action or a refresh failed.
  final Failure? actionFailure;

  MarketplaceOrderDetailsState copyWith({
    String? orderId,
    MarketplaceOrderDetailsStatus? status,
    OrderDetails? Function()? details,
    Failure? Function()? failure,
    OrderDetailsAction? Function()? pendingAction,
    OrderDetailsAction? Function()? doneAction,
    Failure? Function()? actionFailure,
  }) {
    return MarketplaceOrderDetailsState(
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      details: details == null ? this.details : details(),
      failure: failure == null ? this.failure : failure(),
      pendingAction: pendingAction == null
          ? this.pendingAction
          : pendingAction(),
      doneAction: doneAction == null ? this.doneAction : doneAction(),
      actionFailure: actionFailure == null
          ? this.actionFailure
          : actionFailure(),
    );
  }
}
