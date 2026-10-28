import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_request.dart';
import 'package:watad/features/payments/contractor/domain/repositories/contractor_payments_repository.dart';

/// «حفظ» on the bank details screen (GRA-64): adds the account the first
/// time and changes it afterwards, then reads it back, so the screen shows
/// what the server stored.
///
/// A form whose check found a problem is refused with that problem's key,
/// so nothing invalid is sent.
class ContractorSaveBankDetailsUseCase
    implements UseCase<ContractorBankDetails, ContractorBankDetailsRequest> {
  const ContractorSaveBankDetailsUseCase(this._repository);

  final ContractorPaymentsRepository _repository;

  @override
  Future<Result<ContractorBankDetails>> call(
    ContractorBankDetailsRequest params,
  ) async {
    final check = params.check;
    if (check.firstError case final key?) {
      return Failed(ValidationFailure(key));
    }
    final written = params.saved == null
        ? await _repository.addBankDetails(check.details)
        : await _repository.updateBankDetails(check.details);
    if (written case Failed(:final failure)) return Failed(failure);
    return switch (await _repository.getMyBankDetails()) {
      Success(data: final details?) => Success(details),
      // Written, yet not there to read: e.g. the account closed meanwhile.
      Success() => const Failed(NotFoundFailure()),
      Failed(:final failure) => Failed(failure),
    };
  }
}
