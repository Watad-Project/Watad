import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/my_orders.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_my_sales_use_case.dart';

part 'marketplace_sales_event.dart';
part 'marketplace_sales_state.dart';

/// «مبيعاتي» (GRA-71): the orders of my listings, newest first, filtered by
/// status on the phone.
class MarketplaceSalesBloc
    extends Bloc<MarketplaceSalesEvent, MarketplaceSalesState> {
  MarketplaceSalesBloc(this._getSales) : super(const MarketplaceSalesState()) {
    on<MarketplaceSalesFetched>(_onFetched);
    on<MarketplaceSalesFilterSelected>(
      (event, emit) => emit(state.copyWith(filter: () => event.status)),
    );
  }

  final GetMySalesUseCase _getSales;

  Future<void> _onFetched(
    MarketplaceSalesFetched event,
    Emitter<MarketplaceSalesState> emit,
  ) async {
    emit(state.copyWith(status: MarketplaceSalesStatus.loading));
    switch (await _getSales()) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: MarketplaceSalesStatus.success,
            orders: data,
            failure: () => null,
            refreshFailure: () => null,
          ),
        );
      case Failed(:final failure) when state.hasLoaded:
        // The list stays on screen; a snackbar says why it didn't refresh.
        emit(
          state.copyWith(
            status: MarketplaceSalesStatus.success,
            refreshFailure: () => failure,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: MarketplaceSalesStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }
}
