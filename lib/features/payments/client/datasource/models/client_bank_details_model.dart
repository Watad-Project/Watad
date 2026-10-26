import 'package:watad/features/payments/client/domain/entities/client_bank_details.dart';

class ClientBankDetailsModel extends ClientBankDetails {
  const ClientBankDetailsModel({
    required super.beneficiaryName,
    required super.bankName,
    required super.iban,
  });

  /// Maps the `v_contractor_bank_details` columns selected in
  /// ClientPaymentsRemoteDataSourceImpl.
  factory ClientBankDetailsModel.fromJson(Map<String, dynamic> json) =>
      ClientBankDetailsModel(
        beneficiaryName: json['beneficiary_name'] as String,
        bankName: json['bank_name'] as String,
        iban: json['iban'] as String,
      );
}
