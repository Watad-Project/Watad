import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';

/// The bank details form checked by the rules of `contractor_bank_details`
/// (migration 78): the details as they would be saved, and what's wrong
/// with each field as a `validation.*` key, null when the field is fine.
class ContractorBankDetailsCheck {
  const ContractorBankDetailsCheck({
    required this.details,
    this.beneficiaryNameError,
    this.bankNameError,
    this.ibanError,
  });

  /// The trimmed names and the clean IBAN: what would be saved.
  final ContractorBankDetails details;
  final String? beneficiaryNameError;
  final String? bankNameError;
  final String? ibanError;

  /// The first problem, in the order of the form; null when there is none.
  String? get firstError => beneficiaryNameError ?? bankNameError ?? ibanError;

  bool get isValid => firstError == null;
}
