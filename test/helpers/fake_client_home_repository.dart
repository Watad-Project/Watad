import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/client_home_injection.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';

/// A hand-written [ClientHomeRepository] that answers with the results you
/// set (APP_ARCHITECTURE.md §16).
class FakeClientHomeRepository implements ClientHomeRepository {
  Result<ClientHomeProfile> profileResult = const Success(
    ClientHomeProfile(fullName: 'عبدالله الحربي', isPhoneVerified: false),
  );
  Result<List<ClientSuggestedContractor>> contractorsResult = const Success([]);

  /// How many times the contractors were read.
  int contractorReads = 0;

  @override
  Future<Result<ClientHomeProfile>> getProfile() async => profileResult;

  @override
  Future<Result<List<ClientSuggestedContractor>>>
  getSuggestedContractors() async {
    contractorReads++;
    return contractorsResult;
  }
}

/// For tests that open the client's navigation (its «الرئيسية» tab) or the
/// home route: the real registrations, with [repository] in place of
/// Supabase. Reset getIt after the test.
void registerFakeClientHome([FakeClientHomeRepository? repository]) {
  registerClientHomeDependencies(getIt);
  getIt
    ..unregister<ClientHomeRepository>()
    ..registerSingleton<ClientHomeRepository>(
      repository ?? FakeClientHomeRepository(),
    );
}
