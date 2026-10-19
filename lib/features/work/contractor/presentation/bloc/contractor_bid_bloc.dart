import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_edit_offer_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_bid_details_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_submit_offer_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_withdraw_offer_use_case.dart';

part 'contractor_bid_event.dart';
part 'contractor_bid_state.dart';

class ContractorBidBloc extends Bloc<ContractorBidEvent, ContractorBidState> {
  ContractorBidBloc(
    this._getBidDetails,
    this._submitOffer,
    this._editOffer,
    this._withdrawOffer,
  ) : super(const ContractorBidInitial()) {
    on<ContractorBidStarted>(_onStarted);
    on<ContractorBidSubmitted>(_onSubmitted);
    on<ContractorBidWithdrawn>(_onWithdrawn);
  }

  final ContractorGetBidDetailsUseCase _getBidDetails;
  final ContractorSubmitOfferUseCase _submitOffer;
  final ContractorEditOfferUseCase _editOffer;
  final ContractorWithdrawOfferUseCase _withdrawOffer;

  Future<void> _onStarted(
    ContractorBidStarted event,
    Emitter<ContractorBidState> emit,
  ) async {
    emit(const ContractorBidLoadInProgress());
    final result = await _getBidDetails(event.projectId);
    switch (result) {
      case Success(:final data):
        emit(ContractorBidReady(details: data));
      case Failed(:final failure):
        log(
          'ContractorBid Load Error: ${failure.cause ?? failure.messageKey}',
          name: 'watad.work.contractor.bid',
          error: failure.cause,
        );
        emit(ContractorBidLoadFailure(failure));
    }
  }

  Future<void> _onSubmitted(
    ContractorBidSubmitted event,
    Emitter<ContractorBidState> emit,
  ) async {
    final current = state;
    if (current is! ContractorBidReady ||
        current.isSubmitting ||
        current.isWithdrawing) {
      return;
    }

    final details = current.details;
    final project = details.project;
    if (project == null) return;

    final rawAmount = event.amountText.trim();
    final trimmedMessage = event.message.trim();

    String? amountErrorKey;
    Money? parsedMoney;
    if (rawAmount.isEmpty) {
      amountErrorKey = 'work.contractor.bid_amount_required';
    } else {
      parsedMoney = parseBidMoney(rawAmount);
      if (parsedMoney == null || parsedMoney.halalas <= 0) {
        amountErrorKey = 'work.contractor.bid_amount_invalid';
      }
    }

    final messageErrorKey = trimmedMessage.isEmpty
        ? 'work.contractor.bid_message_required'
        : null;

    if (amountErrorKey != null || messageErrorKey != null) {
      emit(
        ContractorBidReady(
          details: details,
          amountErrorKey: amountErrorKey,
          messageErrorKey: messageErrorKey,
        ),
      );
      return;
    }

    emit(ContractorBidReady(details: details, isSubmitting: true));

    final isEditing =
        details.hasPendingOffer && details.existingOfferId != null;
    final result = isEditing
        ? await _editOffer(
            ContractorEditOfferParams(
              offerId: details.existingOfferId!,
              amount: parsedMoney!,
              message: trimmedMessage,
            ),
          )
        : await _submitOffer(
            ContractorSubmitOfferParams(
              projectId: project.id,
              amount: parsedMoney!,
              message: trimmedMessage,
            ),
          );

    switch (result) {
      case Success():
        emit(
          ContractorBidReady(
            details: details,
            completedMessageKey: isEditing
                ? 'work.contractor.offer_updated_success'
                : 'work.contractor.offer_sent_success',
          ),
        );
      case Failed(:final failure):
        log(
          'ContractorBid Submit Error: ${failure.cause ?? failure.messageKey}',
          name: 'watad.work.contractor.bid',
          error: failure.cause,
        );
        emit(ContractorBidReady(details: details, actionFailure: failure));
    }
  }

  Future<void> _onWithdrawn(
    ContractorBidWithdrawn event,
    Emitter<ContractorBidState> emit,
  ) async {
    final current = state;
    if (current is! ContractorBidReady ||
        current.isSubmitting ||
        current.isWithdrawing) {
      return;
    }

    final details = current.details;
    final offerId = details.existingOfferId;
    if (!details.hasPendingOffer || offerId == null) return;

    emit(ContractorBidReady(details: details, isWithdrawing: true));

    final result = await _withdrawOffer(offerId);
    switch (result) {
      case Success():
        emit(
          ContractorBidReady(
            details: details,
            completedMessageKey: 'work.contractor.offer_withdrawn_success',
          ),
        );
      case Failed(:final failure):
        log(
          'ContractorBid Withdraw Error: '
          '${failure.cause ?? failure.messageKey}',
          name: 'watad.work.contractor.bid',
          error: failure.cause,
        );
        emit(ContractorBidReady(details: details, actionFailure: failure));
    }
  }

  /// Parses an input string (Western or Arabic-Indic digits, up to 2 decimals)
  /// into [Money], or returns `null` when invalid.
  static Money? parseBidMoney(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.writeCharCode(rune);
      } else if (rune >= 0x660 && rune <= 0x669) {
        buffer.writeCharCode(rune - 0x660 + 0x30);
      } else if (rune >= 0x6F0 && rune <= 0x6F9) {
        buffer.writeCharCode(rune - 0x6F0 + 0x30);
      } else if (rune == 0x2E || rune == 0x66B) {
        buffer.write('.');
      } else if (rune == 0x2C || rune == 0x66C || rune == 0x20) {
        // Ignore thousand separators and spaces.
        continue;
      } else {
        return null;
      }
    }
    final normalized = buffer.toString();
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(normalized)) {
      return null;
    }
    final parsedValue = double.tryParse(normalized);
    if (parsedValue == null || parsedValue <= 0) return null;
    return Money.fromJson(parsedValue);
  }
}
