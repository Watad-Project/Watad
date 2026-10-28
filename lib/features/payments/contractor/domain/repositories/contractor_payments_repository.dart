import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';

abstract interface class ContractorPaymentsRepository {
  /// The bank account the signed-in contractor is paid on; null until they
  /// add it.
  Future<Result<ContractorBankDetails?>> getMyBankDetails();

  /// Saves the contractor's bank account for the first time.
  Future<Result<void>> addBankDetails(ContractorBankDetails details);

  /// Changes the contractor's saved bank account to [details].
  Future<Result<void>> updateBankDetails(ContractorBankDetails details);
}
