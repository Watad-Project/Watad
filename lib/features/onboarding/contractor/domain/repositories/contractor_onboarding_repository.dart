import 'package:watad/core/error/result.dart';

abstract interface class ContractorOnboardingRepository {
  Future<Result<void>> saveSpecialty(String specialty);
}
