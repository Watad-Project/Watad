import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';

/// Signs out a contractor while on the KYC screen.
class ContractorSignOutUseCase implements UseCase<void, NoParams> {
  const ContractorSignOutUseCase(this._repository);

  final ContractorKycRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.signOut();
}
