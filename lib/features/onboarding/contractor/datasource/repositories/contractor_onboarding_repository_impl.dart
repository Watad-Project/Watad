import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/onboarding/contractor/datasource/remote/contractor_onboarding_remote_data_source.dart';
import 'package:watad/features/onboarding/contractor/domain/repositories/contractor_onboarding_repository.dart';

class ContractorOnboardingRepositoryImpl
    implements ContractorOnboardingRepository {
  const ContractorOnboardingRepositoryImpl(this._remote);

  final ContractorOnboardingRemoteDataSource _remote;

  @override
  Future<Result<void>> saveSpecialty(String specialty) {
    return guardSupabaseCall(() => _remote.saveSpecialty(specialty));
  }
}
