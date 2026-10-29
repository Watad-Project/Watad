part of 'contractor_bank_details_bloc.dart';

enum ContractorBankDetailsStatus { initial, loading, success, failure }

/// How a [ContractorBankDetailsMessage] shows: with a green check, as a
/// plain note, or with a red mark.
enum ContractorBankDetailsMessageKind { success, info, error }

/// A message to show once, as a translation key.
final class ContractorBankDetailsMessage {
  const ContractorBankDetailsMessage(this.key, this.kind);

  final String key;
  final ContractorBankDetailsMessageKind kind;
}

final class ContractorBankDetailsState {
  const ContractorBankDetailsState({
    this.status = ContractorBankDetailsStatus.initial,
    this.saved,
    this.failure,
    this.isEditing = false,
    this.check,
    this.isSaving = false,
    this.message,
  });

  final ContractorBankDetailsStatus status;

  /// What the server has; null until the contractor adds their details.
  final ContractorBankDetails? saved;

  /// Why the page couldn't load.
  final Failure? failure;

  /// «تعديل» opened the form on the saved details.
  final bool isEditing;

  /// The form as typed, cleaned and checked; null until the contractor
  /// changes a field.
  final ContractorBankDetailsCheck? check;
  final bool isSaving;
  final ContractorBankDetailsMessage? message;

  /// The form shows on first use, and while editing.
  bool get showsForm =>
      status == ContractorBankDetailsStatus.success &&
      (saved == null || isEditing);

  /// All three fields are right, and something differs from what's saved.
  bool get canSave {
    final check = this.check;
    if (check == null || !check.isValid || isSaving) return false;
    final saved = this.saved;
    final details = check.details;
    return saved == null ||
        details.beneficiaryName != saved.beneficiaryName ||
        details.bankName != saved.bankName ||
        details.iban != saved.iban;
  }

  /// Each field's problem, as a `validation.*` key, once the field has
  /// something in it. An empty field shows none: its label already says
  /// it's required.
  String? get beneficiaryNameError =>
      _shown(check?.details.beneficiaryName, check?.beneficiaryNameError);

  String? get bankNameError =>
      _shown(check?.details.bankName, check?.bankNameError);

  String? get ibanError => _shown(check?.details.iban, check?.ibanError);

  static String? _shown(String? value, String? error) =>
      value == null || value.isEmpty ? null : error;

  ContractorBankDetailsState copyWith({
    ContractorBankDetailsStatus? status,
    ContractorBankDetails? Function()? saved,
    Failure? Function()? failure,
    bool? isEditing,
    ContractorBankDetailsCheck? Function()? check,
    bool? isSaving,
    ContractorBankDetailsMessage? Function()? message,
  }) {
    return ContractorBankDetailsState(
      status: status ?? this.status,
      saved: saved == null ? this.saved : saved(),
      failure: failure == null ? this.failure : failure(),
      isEditing: isEditing ?? this.isEditing,
      check: check == null ? this.check : check(),
      isSaving: isSaving ?? this.isSaving,
      message: message == null ? this.message : message(),
    );
  }
}
