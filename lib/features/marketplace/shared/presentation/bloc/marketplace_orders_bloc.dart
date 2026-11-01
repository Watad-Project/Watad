import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/my_orders.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_orders_use_case.dart';

part 'marketplace_orders_event.dart';
part 'marketplace_orders_state.dart';

/// «طلباتي» (GRA-69): the orders I bought, newest first, filtered by
/// status on the phone.
class MarketplaceOrdersBloc
    extends Bloc<MarketplaceOrdersEvent, MarketplaceOrdersState> {
  MarketplaceOrdersBloc(this._getOrders)
    : super(const MarketplaceOrdersState()) {
    on<MarketplaceOrdersFetched>(_onFetched);
    on<MarketplaceOrdersFilterSelected>(
      (event, emit) => emit(state.copyWith(filter: () => event.status)),
    );
  }

  final GetMyOrdersUseCase _getOrders;

  Future<void> _onFetched(
    MarketplaceOrdersFetched event,
    Emitter<MarketplaceOrdersState> emit,
  ) async {
    emit(state.copyWith(status: MarketplaceOrdersStatus.loading));
    switch (await _getOrders()) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: MarketplaceOrdersStatus.success,
            orders: data,
            failure: () => null,
            refreshFailure: () => null,
          ),
        );
      case Failed(:final failure) when state.hasLoaded:
        // The list stays on screen; a snackbar says why it didn't refresh.
        emit(
          state.copyWith(
            status: MarketplaceOrdersStatus.success,
            refreshFailure: () => failure,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MarketplaceOrdersStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }
}
