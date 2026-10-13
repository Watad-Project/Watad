import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/onboarding/shared/datasource/local/onboarding_local_data_source.dart';
import 'package:watad/features/onboarding/shared/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._localDataSource);

  final OnboardingLocalDataSource _localDataSource;

  @override
  Future<Result<void>> markOnboardingSeen() =>
      guardSupabaseCall(_localDataSource.setOnboardingSeen);
}
