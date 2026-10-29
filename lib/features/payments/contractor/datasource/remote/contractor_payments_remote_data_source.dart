import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/payments/contractor/datasource/models/contractor_bank_details_model.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';

abstract interface class ContractorPaymentsRemoteDataSource {
  /// The signed-in contractor's row of `v_contractor_bank_details`
  /// (`is_mine`), or null when they haven't added their bank details.
  Future<ContractorBankDetailsModel?> getMyBankDetails();

  /// Inserts [details] into `contractor_bank_details`. `user_id` isn't sent:
  /// the table takes it from the session (`default auth.uid()`).
  Future<void> addBankDetails(ContractorBankDetails details);

  /// Updates the signed-in contractor's row of `contractor_bank_details`.
  Future<void> updateBankDetails(ContractorBankDetails details);
}

class ContractorPaymentsRemoteDataSourceImpl
    implements ContractorPaymentsRemoteDataSource {
  const ContractorPaymentsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<ContractorBankDetailsModel?> getMyBankDetails() async {
    final row = await _client
        .from('v_contractor_bank_details')
        .select('beneficiary_name, bank_name, iban')
        .eq('is_mine', true)
        .maybeSingle();
    return row == null ? null : ContractorBankDetailsModel.fromJson(row);
  }

  @override
  Future<void> addBankDetails(ContractorBankDetails details) async {
    // Only the INSERT columns of ARCHITECTURE.md §3a.
    await _client.from('contractor_bank_details').insert({
      'beneficiary_name': details.beneficiaryName,
      'bank_name': details.bankName,
      'iban': details.iban,
    });
  }

  @override
  Future<void> updateBankDetails(ContractorBankDetails details) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('User not authenticated');
    }
    // Only the UPDATE columns of ARCHITECTURE.md §3a.
    await _client
        .from('contractor_bank_details')
        .update({
          'beneficiary_name': details.beneficiaryName,
          'bank_name': details.bankName,
          'iban': details.iban,
        })
        .eq('user_id', userId);
  }
}
