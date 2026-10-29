/// The bank details form as the contractor typed or pasted it (GRA-64),
/// before it's cleaned and checked: spaces, dashes, Arabic digits and lower
/// case are all fine here.
class ContractorBankDetailsDraft {
  const ContractorBankDetailsDraft({
    required this.beneficiaryName,
    required this.bankName,
    required this.iban,
  });

  final String beneficiaryName;
  final String bankName;
  final String iban;
}
