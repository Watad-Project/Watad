/// Where the contractor of one of the client's projects is paid by bank
/// transfer (GRA-52): a `v_contractor_bank_details` row.
class ClientBankDetails {
  const ClientBankDetails({
    required this.beneficiaryName,
    required this.bankName,
    required this.iban,
  });

  final String beneficiaryName;
  final String bankName;

  /// A Saudi IBAN as the server keeps it: `SA` and 22 characters, no spaces.
  final String iban;
}
