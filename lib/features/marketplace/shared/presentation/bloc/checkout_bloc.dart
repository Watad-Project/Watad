import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_request.dart';
import 'package:watad/features/marketplace/shared/domain/entities/checkout_review.dart';
import 'package:watad/features/marketplace/shared/domain/entities/placed_order.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/place_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/review_checkout_use_case.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

/// Checkout for one seller's group: what will be ordered, where it goes,
/// how it's paid, and «تأكيد الطلب».
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(this._review, this._placeOrder) : super(const CheckoutState()) {
    on<CheckoutStarted>(_onStarted);
    on<CheckoutAddressSelected>(
      (event, emit) => emit(state.copyWith(addressId: () => event.addressId)),
    );
    on<CheckoutMethodSelected>(
      (event, emit) => emit(state.copyWith(method: () => event.method)),
    );
    on<CheckoutAddressAdded>(
      (event, emit) => _load(emit, selectAddressId: event.addressId),
    );
    on<CheckoutSubmitted>(_onSubmitted);
  }

  final ReviewCheckoutUseCase _review;
  final PlaceOrderUseCase _placeOrder;

  Future<void> _onStarted(
    CheckoutStarted event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(sellerId: event.sellerId));
    await _load(emit);
  }

  Future<void> _load(
    Emitter<CheckoutState> emit, {
    String? selectAddressId,
  }) async {
    emit(state.copyWith(status: CheckoutStatus.loading));
    final result = await _review(state.sellerId);
    switch (result) {
      case Success(:final data):
        final ids = [for (final address in data.addresses) address.id];
        final wanted = selectAddressId ?? state.addressId;
        emit(
          state.copyWith(
            status: CheckoutStatus.ready,
            review: () => data,
            addressId: () => ids.contains(wanted) ? wanted : ids.firstOrNull,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: CheckoutStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onSubmitted(
    CheckoutSubmitted event,
    Emitter<CheckoutState> emit,
  ) async {
    final (review, addressId, method) = (
      state.review,
      state.addressId,
      state.method,
    );
    if (!state.canSubmit || review == null) return;
    emit(state.copyWith(submitStatus: CheckoutSubmitStatus.submitting));
    final result = await _placeOrder(
      CheckoutRequest(
        sellerId: state.sellerId,
        lines: [for (final entry in review.entries) entry.line],
        method: method!,
        addressId: addressId!,
      ),
    );
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            submitStatus: CheckoutSubmitStatus.placed,
            placed: () => data,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            submitStatus: CheckoutSubmitStatus.failed,
            submitFailure: () => failure,
          ),
        );
        // Show what the server has now: a price, the stock or the unpaid
        // orders may be what changed.
        await _load(emit);
    }
  }
}
