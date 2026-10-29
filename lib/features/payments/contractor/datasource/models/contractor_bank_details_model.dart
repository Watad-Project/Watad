import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';

class ContractorBankDetailsModel extends ContractorBankDetails {
  const ContractorBankDetailsModel({
    required super.beneficiaryName,
    required super.bankName,
    required super.iban,
  });

  /// Maps the `v_contractor_bank_details` columns selected in
  /// ContractorPaymentsRemoteDataSourceImpl.
  factory ContractorBankDetailsModel.fromJson(Map<String, dynamic> json) =>
      ContractorBankDetailsModel(
        beneficiaryName: json['beneficiary_name'] as String,
        bankName: json['bank_name'] as String,
        iban: json['iban'] as String,
      );
}
