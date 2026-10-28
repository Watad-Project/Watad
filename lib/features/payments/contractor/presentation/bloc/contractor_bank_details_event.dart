part of 'contractor_bank_details_bloc.dart';

sealed class ContractorBankDetailsEvent {
  const ContractorBankDetailsEvent();
}

/// The page opened, or the contractor tapped retry.
final class ContractorBankDetailsFetched extends ContractorBankDetailsEvent {
  const ContractorBankDetailsFetched();
}

/// «تعديل»: the form opens on the saved details.
final class ContractorBankDetailsEditStarted
    extends ContractorBankDetailsEvent {
  const ContractorBankDetailsEditStarted();
}

/// «إلغاء»: back to the saved details, without saving.
final class ContractorBankDetailsEditCancelled
    extends ContractorBankDetailsEvent {
  const ContractorBankDetailsEditCancelled();
}

/// The contractor typed or pasted in one of the three fields.
final class ContractorBankDetailsChanged extends ContractorBankDetailsEvent {
  const ContractorBankDetailsChanged(this.draft);

  final ContractorBankDetailsDraft draft;
}

/// «حفظ».
final class ContractorBankDetailsSubmitted extends ContractorBankDetailsEvent {
  const ContractorBankDetailsSubmitted();
}
