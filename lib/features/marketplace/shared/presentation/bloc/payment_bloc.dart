import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_check.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_payment.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';
import 'package:watad/features/marketplace/shared/domain/entities/payment_brand.dart';
import 'package:watad/features/marketplace/shared/domain/entities/payment_outcome.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/check_card_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/get_order_use_case.dart';
import 'package:watad/features/marketplace/shared/domain/usecases/pay_order_use_case.dart';

part 'payment_event.dart';
part 'payment_state.dart';

/// DEMO ONLY: the payment page of an unpaid order (ARCHITECTURE.md §15).
///
/// The card fields come in once, in [PaymentCardSubmitted], and go straight
/// to [CheckCardUseCase]. The state keeps only the order, the status and
/// the error keys of the fields: never the full number or the CVV.
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc(
    this._getOrder,
    this._checkCard,
    this._payOrder, {
    this.processingDelay = const Duration(seconds: 2),
  }) : super(const PaymentState()) {
    on<PaymentStarted>(_onStarted);
    on<PaymentRetried>((event, emit) => _load(emit));
    on<PaymentCardSubmitted>(_onCardSubmitted);
    on<PaymentWalletConfirmed>(_onWalletConfirmed);
  }

  final GetOrderUseCase _getOrder;
  final CheckCardUseCase _checkCard;
  final PayOrderUseCase _payOrder;

  /// How long «جارٍ الدفع» shows before the payment is sent, like a real
  /// gateway; zero in tests.
  final Duration processingDelay;

  Future<void> _onStarted(
    PaymentStarted event,
    Emitter<PaymentState> emit,
  ) async {
    emit(state.copyWith(orderId: event.orderId));
    await _load(emit);
  }

  Future<void> _load(Emitter<PaymentState> emit) async {
    emit(
      state.copyWith(
        status: PaymentPageStatus.loading,
        cardCheck: () => null,
        failure: () => null,
      ),
    );
    final result = await _getOrder(state.orderId);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: data.isPayableByMe
                ? PaymentPageStatus.ready
                : PaymentPageStatus.notPayable,
            order: () => data,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PaymentPageStatus.loadFailure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onCardSubmitted(
    PaymentCardSubmitted event,
    Emitter<PaymentState> emit,
  ) async {
    final order = state.order;
    if (order == null || state.status != PaymentPageStatus.ready) return;
    final result = await _checkCard((
      method: order.paymentMethod,
      number: event.number,
      expiry: event.expiry,
      cvv: event.cvv,
      name: event.name,
    ));
    switch (result) {
      case Success(:final data) when data.payment == null:
        emit(state.copyWith(cardCheck: () => data));
      case Success(:final data):
        await _pay(emit, data.payment!, succeed: !data.declines);
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PaymentPageStatus.payFailure,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _onWalletConfirmed(
    PaymentWalletConfirmed event,
    Emitter<PaymentState> emit,
  ) async {
    final order = state.order;
    if (order == null || state.status != PaymentPageStatus.ready) return;
    final brand = PaymentBrand.walletOf(order.paymentMethod);
    if (brand == null) return;
    await _pay(emit, CardPayment.wallet(brand), succeed: true);
  }

  Future<void> _pay(
    Emitter<PaymentState> emit,
    CardPayment payment, {
    required bool succeed,
  }) async {
    emit(
      state.copyWith(
        status: PaymentPageStatus.processing,
        cardCheck: () => null,
      ),
    );
    if (processingDelay > Duration.zero) {
      await Future<void>.delayed(processingDelay);
    }
    final result = await _payOrder((
      orderId: state.orderId,
      payment: payment,
      succeed: succeed,
    ));
    switch (result) {
      case Success(data: PaymentOutcome.paid):
        emit(state.copyWith(status: PaymentPageStatus.paid));
      case Success(data: PaymentOutcome.declined):
        emit(state.copyWith(status: PaymentPageStatus.declined));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: PaymentPageStatus.payFailure,
            failure: () => failure,
          ),
        );
    }
  }
}
