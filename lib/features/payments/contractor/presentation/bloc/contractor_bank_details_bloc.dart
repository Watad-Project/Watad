import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_check.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_draft.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_request.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_check_bank_details_use_case.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_get_bank_details_use_case.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_save_bank_details_use_case.dart';

part 'contractor_bank_details_event.dart';
part 'contractor_bank_details_state.dart';

/// «الحساب البنكي» (GRA-64): the saved bank account, or the form on first
/// use. «تعديل» opens the form on the saved details, every change is
/// checked, and «حفظ» saves the form and shows what the server stored.
class ContractorBankDetailsBloc
    extends Bloc<ContractorBankDetailsEvent, ContractorBankDetailsState> {
  ContractorBankDetailsBloc(
    this._getBankDetails,
    this._checkBankDetails,
    this._saveBankDetails,
  ) : super(const ContractorBankDetailsState()) {
    on<ContractorBankDetailsFetched>(_onFetched);
    on<ContractorBankDetailsEditStarted>(_onEditStarted);
    on<ContractorBankDetailsEditCancelled>(_onEditCancelled);
    on<ContractorBankDetailsChanged>(_onChanged);
    on<ContractorBankDetailsSubmitted>(_onSubmitted);
  }

  final ContractorGetBankDetailsUseCase _getBankDetails;
  final ContractorCheckBankDetailsUseCase _checkBankDetails;
  final ContractorSaveBankDetailsUseCase _saveBankDetails;

  Future<void> _onFetched(
    ContractorBankDetailsFetched event,
    Emitter<ContractorBankDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ContractorBankDetailsStatus.loading,
        failure: () => null,
      ),
    );
    final result = await _getBankDetails(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          ContractorBankDetailsState(
            status: ContractorBankDetailsStatus.success,
            saved: data,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ContractorBankDetailsStatus.failure,
            failure: () => failure,
          ),
        );
    }
  }

  void _onEditStarted(
    ContractorBankDetailsEditStarted event,
    Emitter<ContractorBankDetailsState> emit,
  ) {
    if (state.saved == null || state.isEditing) return;
    // The form opens on the saved details: nothing to save until a change.
    emit(
      state.copyWith(isEditing: true, check: () => null, message: () => null),
    );
  }

  void _onEditCancelled(
    ContractorBankDetailsEditCancelled event,
    Emitter<ContractorBankDetailsState> emit,
  ) {
    if (!state.isEditing || state.isSaving) return;
    emit(
      state.copyWith(isEditing: false, check: () => null, message: () => null),
    );
  }

  Future<void> _onChanged(
    ContractorBankDetailsChanged event,
    Emitter<ContractorBankDetailsState> emit,
  ) async {
    if (!state.showsForm) return;
    final result = await _checkBankDetails(event.draft);
    if (!state.showsForm) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(check: () => data));
      case Failed(:final failure):
        emit(
          state.copyWith(
            message: () => ContractorBankDetailsMessage(
              failure.messageKey,
              ContractorBankDetailsMessageKind.error,
            ),
          ),
        );
    }
  }

  Future<void> _onSubmitted(
    ContractorBankDetailsSubmitted event,
    Emitter<ContractorBankDetailsState> emit,
  ) async {
    final check = state.check;
    if (check == null || !state.canSave) return;
    final saved = state.saved;
    emit(state.copyWith(isSaving: true, message: () => null));
    final result = await _saveBankDetails(
      ContractorBankDetailsRequest(check: check, saved: saved),
    );
    switch (result) {
      case Success(:final data):
        emit(
          ContractorBankDetailsState(
            status: ContractorBankDetailsStatus.success,
            saved: data,
            message: const ContractorBankDetailsMessage(
              'payments.contractor.saved',
              ContractorBankDetailsMessageKind.success,
            ),
          ),
        );
      case Failed(failure: ConflictFailure()) when saved == null:
        // Added meanwhile, e.g. from another device: show what's there.
        await _showSavedElsewhere(emit);
      case Failed(:final failure):
        emit(
          state.copyWith(
            isSaving: false,
            message: () => ContractorBankDetailsMessage(
              failure.messageKey,
              ContractorBankDetailsMessageKind.error,
            ),
          ),
        );
    }
  }

  Future<void> _showSavedElsewhere(
    Emitter<ContractorBankDetailsState> emit,
  ) async {
    final result = await _getBankDetails(const NoParams());
    switch (result) {
      case Success(data: final saved?):
        emit(
          ContractorBankDetailsState(
            status: ContractorBankDetailsStatus.success,
            saved: saved,
            message: const ContractorBankDetailsMessage(
              'payments.contractor.already_saved',
              ContractorBankDetailsMessageKind.info,
            ),
          ),
        );
      case Success():
        // The server said they exist, yet they don't: keep the form.
        emit(
          state.copyWith(
            isSaving: false,
            message: () => const ContractorBankDetailsMessage(
              'errors.conflict',
              ContractorBankDetailsMessageKind.error,
            ),
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            isSaving: false,
            message: () => ContractorBankDetailsMessage(
              failure.messageKey,
              ContractorBankDetailsMessageKind.error,
            ),
          ),
        );
    }
  }
}
