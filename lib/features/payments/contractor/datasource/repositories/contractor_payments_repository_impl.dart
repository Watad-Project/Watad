import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/payments/contractor/datasource/remote/contractor_payments_remote_data_source.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/repositories/contractor_payments_repository.dart';

class ContractorPaymentsRepositoryImpl implements ContractorPaymentsRepository {
  const ContractorPaymentsRepositoryImpl(this._remote);

  final ContractorPaymentsRemoteDataSource _remote;

  @override
  Future<Result<ContractorBankDetails?>> getMyBankDetails() =>
      guardSupabaseCall(_remote.getMyBankDetails);

  @override
  Future<Result<void>> addBankDetails(ContractorBankDetails details) =>
      guardSupabaseCall(() => _remote.addBankDetails(details));

  @override
  Future<Result<void>> updateBankDetails(ContractorBankDetails details) =>
      guardSupabaseCall(() => _remote.updateBankDetails(details));
}
