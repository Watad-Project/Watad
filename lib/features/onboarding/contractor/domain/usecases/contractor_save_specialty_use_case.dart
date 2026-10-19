import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/onboarding/contractor/domain/repositories/contractor_onboarding_repository.dart';

class ContractorSaveSpecialtyUseCase implements UseCase<void, String> {
  const ContractorSaveSpecialtyUseCase(this._repository);

  final ContractorOnboardingRepository _repository;

  @override
  Future<Result<void>> call(String params) {
    return _repository.saveSpecialty(params);
  }
}
