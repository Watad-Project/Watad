import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer_outcome.dart';
import 'package:watad/features/payments/client/domain/entities/client_bank_transfer_request.dart';
import 'package:watad/features/payments/client/domain/entities/client_payment_selection.dart';
import 'package:watad/features/payments/client/domain/entities/client_receipt.dart';
import 'package:watad/features/payments/client/domain/usecases/client_check_receipt_use_case.dart';
import 'package:watad/features/payments/client/domain/usecases/client_get_bank_transfer_use_case.dart';
import 'package:watad/features/payments/client/domain/usecases/client_submit_bank_transfer_use_case.dart';

part 'client_bank_transfer_event.dart';
part 'client_bank_transfer_state.dart';

/// «تحويل بنكي» (GRA-52): where to send the money, the receipt the client
/// picks, and sending it for each selected task.
class ClientBankTransferBloc
    extends Bloc<ClientBankTransferEvent, ClientBankTransferState> {
  ClientBankTransferBloc(this._getTransfer, this._checkReceipt, this._submit)
    : super(const ClientBankTransferState()) {
    on<ClientBankTransferFetched>(_onFetched);
    on<ClientBankTransferReceiptPicked>(_onReceiptPicked);
    on<ClientBankTransferSubmitted>(_onSubmitted);
  }

  final ClientGetBankTransferUseCase _getTransfer;
  final ClientCheckReceiptUseCase _checkReceipt;
  final ClientSubmitBankTransferUseCase _submit;

  Future<void> _onFetched(
    ClientBankTransferFetched event,
    Emitter<ClientBankTransferState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClientBankTransferStatus.loading,
        selection: () => event.selection,
      ),
    );
    await _load(event.selection, emit);
  }

  Future<void> _onReceiptPicked(
    ClientBankTransferReceiptPicked event,
    Emitter<ClientBankTransferState> emit,
  ) async {
    final result = await _checkReceipt(event.receipt);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(receipt: () => data, message: () => null));
      case Failed(:final failure):
        // The receipt picked before, if any, stays.
        emit(
          state.copyWith(
            message: () =>
                ClientBankTransferMessage(failure.messageKey, isError: true),
          ),
        );
    }
  }

  Future<void> _onSubmitted(
    ClientBankTransferSubmitted event,
    Emitter<ClientBankTransferState> emit,
  ) async {
    final selection = state.selection;
    final receipt = state.receipt;
    if (selection == null || receipt == null || state.isSending) return;
    emit(state.copyWith(isSending: true, message: () => null));
    final result = await _submit(
      ClientBankTransferRequest(selection: selection, receipt: receipt),
    );
    switch (result) {
      case Failed(:final failure):
        emit(
          state.copyWith(
            isSending: false,
            message: () =>
                ClientBankTransferMessage(failure.messageKey, isError: true),
          ),
        );
      case Success(:final data) when data.isComplete && data.sent.isNotEmpty:
        emit(state.copyWith(isSending: false, isSent: true));
      case Success(:final data) when data.isComplete:
        // Nothing was waiting anymore: show the tasks as they are now.
        await _load(selection, emit);
        emit(
          state.copyWith(
            isSending: false,
            outcome: () => null,
            message: () => const ClientBankTransferMessage(
              'payments.client.nothing_to_send',
              isError: false,
            ),
          ),
        );
      case Success(:final data):
        // Some went, some didn't: say which, with the tasks as they are now.
        await _load(selection, emit);
        emit(
          state.copyWith(
            isSending: false,
            outcome: () => data,
            message: () => ClientBankTransferMessage(
              data.failure?.messageKey ?? 'errors.unknown',
              isError: true,
            ),
          ),
        );
    }
  }

  Future<void> _load(
    ClientPaymentSelection selection,
    Emitter<ClientBankTransferState> emit,
  ) async {
    final result = await _getTransfer(selection);
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: ClientBankTransferStatus.success,
            transfer: () => data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ClientBankTransferStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }
}
