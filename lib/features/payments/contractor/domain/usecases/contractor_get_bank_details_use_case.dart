import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/repositories/contractor_payments_repository.dart';

/// The bank account the contractor saved for bank transfers (GRA-64); null
/// on first use, before they add it.
class ContractorGetBankDetailsUseCase
    implements UseCase<ContractorBankDetails?, NoParams> {
  const ContractorGetBankDetailsUseCase(this._repository);

  final ContractorPaymentsRepository _repository;

  @override
  Future<Result<ContractorBankDetails?>> call(NoParams params) =>
      _repository.getMyBankDetails();
}
