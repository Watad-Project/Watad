import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_details.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/cancel_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/confirm_order_delivered_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_order_details_use_case.dart';

part 'marketplace_order_details_event.dart';
part 'marketplace_order_details_state.dart';

/// The order details page (GRA-69), for the buyer and the seller: the
/// order, its products and timeline, and the buyer's cancel and «تم
/// الاستلام». Every action reloads the order from the server.
class MarketplaceOrderDetailsBloc
    extends Bloc<MarketplaceOrderDetailsEvent, MarketplaceOrderDetailsState> {
  MarketplaceOrderDetailsBloc(this._getDetails, this._cancel, this._confirm)
    : super(const MarketplaceOrderDetailsState()) {
    on<MarketplaceOrderDetailsFetched>(_onFetched);
    on<MarketplaceOrderCancelled>(
      (event, emit) => _act(emit, OrderDetailsAction.cancel),
    );
    on<MarketplaceOrderDeliveryConfirmed>(
      (event, emit) => _act(emit, OrderDetailsAction.confirmDelivery),
    );
  }

  final GetOrderDetailsUseCase _getDetails;
  final CancelOrderUseCase _cancel;
  final ConfirmOrderDeliveredUseCase _confirm;

  Future<void> _onFetched(
    MarketplaceOrderDetailsFetched event,
    Emitter<MarketplaceOrderDetailsState> emit,
  ) async {
    final orderId = event.orderId ?? state.orderId;
    if (orderId == null) return;
    emit(
      state.copyWith(
        orderId: orderId,
        status: MarketplaceOrderDetailsStatus.loading,
      ),
    );
    await _load(emit, orderId);
  }

  Future<void> _load(
    Emitter<MarketplaceOrderDetailsState> emit,
    String orderId,
  ) async {
    switch (await _getDetails(orderId)) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: MarketplaceOrderDetailsStatus.success,
            details: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure) when state.details != null:
        // The order stays on screen; a snackbar says why it didn't refresh.
        emit(
          state.copyWith(
            status: MarketplaceOrderDetailsStatus.success,
            actionFailure: () => failure,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MarketplaceOrderDetailsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _act(
    Emitter<MarketplaceOrderDetailsState> emit,
    OrderDetailsAction action,
  ) async {
    final order = state.details?.order;
    if (order == null || state.pendingAction != null) return;
    emit(
      state.copyWith(
        pendingAction: () => action,
        actionFailure: () => null,
        doneAction: () => null,
      ),
    );
    final result = switch (action) {
      OrderDetailsAction.cancel => await _cancel(order),
      OrderDetailsAction.confirmDelivery => await _confirm(order),
    };
    switch (result) {
      case Success():
        emit(
          state.copyWith(pendingAction: () => null, doneAction: () => action),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            pendingAction: () => null,
            actionFailure: () => failure,
          ),
        );
    }
    // Done or refused, the page shows what the server has now.
    await _load(emit, order.id);
  }
}
