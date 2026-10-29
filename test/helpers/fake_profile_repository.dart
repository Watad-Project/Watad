import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/profile/client/client_profile_injection.dart';
import 'package:watad/features/profile/contractor/contractor_profile_injection.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';
import 'package:watad/features/profile/shared/profile_injection.dart';

/// A client without a photo.
const MyProfile fakeClientProfile = MyProfile(
  id: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
  fullName: 'سارة العتيبي',
  isSuspended: false,
);

/// A verified contractor whose specialty was saved in Arabic.
const MyProfile fakeContractorProfile = MyProfile(
  id: '3f2a1b4c-5d6e-4f70-8a9b-0c1d2e3f4a5b',
  fullName: 'خالد الحربي',
  isSuspended: false,
  business: MyProfileBusiness(
    companyName: 'مؤسسة البناء المتين',
    crNumber: '1010123456',
    specializedField: 'مقاولات عامة',
    verificationStatus: VerificationStatus.verified,
    city: 'المدينة المنورة',
  ),
);

/// A hand-written [ProfileRepository] (APP_ARCHITECTURE.md §16). Set a
/// result to change what a call answers; [calls] records the calls in order.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    this.profileResult = const Success(fakeClientProfile),
    this.ratingResult = const Success(ProfileRating(count: 0)),
  });

  Result<MyProfile> profileResult;
  Result<ProfileRating> ratingResult;

  /// E.g. `getMyProfile`, then `getRating(<user id>)`.
  final List<String> calls = [];

  @override
  Future<Result<MyProfile>> getMyProfile() async {
    calls.add('getMyProfile');
    return profileResult;
  }

  @override
  Future<Result<ProfileRating>> getRating(String userId) async {
    calls.add('getRating($userId)');
    return ratingResult;
  }
}

/// For tests that open the client's «حسابي», by its route or in the client's
/// navigation: the real registrations, with [repository] in place of
/// Supabase. Reset getIt after the test.
void registerFakeClientProfile([FakeProfileRepository? repository]) {
  registerProfileDependencies(getIt);
  registerClientProfileDependencies(getIt);
  _useRepository(repository ?? FakeProfileRepository());
}

/// The same for the contractor's «منشأتي»; by default a verified business.
void registerFakeContractorProfile([FakeProfileRepository? repository]) {
  registerProfileDependencies(getIt);
  registerContractorProfileDependencies(getIt);
  _useRepository(
    repository ??
        FakeProfileRepository(
          profileResult: const Success(fakeContractorProfile),
        ),
  );
}

void _useRepository(ProfileRepository repository) {
  getIt
    ..unregister<ProfileRepository>()
    ..registerSingleton<ProfileRepository>(repository);
}
