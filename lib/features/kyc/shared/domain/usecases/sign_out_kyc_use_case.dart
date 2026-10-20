import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';

/// Signs out the user from the KYC status screen.
class SignOutKycUseCase implements UseCase<void, NoParams> {
  const SignOutKycUseCase(this._repository);

  final KycRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.signOut();
}
