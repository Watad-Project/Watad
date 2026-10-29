/// The account a contractor is paid on by bank transfer (GRA-64): their own
/// `v_contractor_bank_details` row (`is_mine`), and what the bank details
/// screen writes to `contractor_bank_details`.
class ContractorBankDetails {
  const ContractorBankDetails({
    required this.beneficiaryName,
    required this.bankName,
    required this.iban,
  });

  /// The account holder's name, as the bank has it.
  final String beneficiaryName;
  final String bankName;

  /// A Saudi IBAN as the server keeps it: `SA` and 22 characters, no spaces.
  final String iban;
}
