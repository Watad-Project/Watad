import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/profile/client/client_profile_injection.dart';
import 'package:watad/features/profile/contractor/contractor_profile_injection.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_business_changes.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_identity.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_market_item.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_place.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_review.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_reviews_query.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_user_write.dart';
import 'package:watad/features/profile/shared/domain/entities/public_profile.dart';
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

/// The ID number and phone a client gave at sign-up.
const ProfileIdentity fakeIdentity = ProfileIdentity(
  nationalId: '1012345678',
  phone: '+966512345678',
);

/// A verified contractor's public profile, last seen on 30 October.
final PublicProfile fakePublicProfile = PublicProfile(
  id: fakeContractorProfile.id,
  displayName: 'مؤسسة البناء المتين',
  isDeleted: false,
  memberSince: DateTime.utc(2026, 9, 14),
  isBusiness: true,
  companyName: 'مؤسسة البناء المتين',
  specialty: 'مقاولات عامة',
  isVerifiedBusiness: true,
  rating: const ProfileRating(count: 12, average: 4.8),
  lastSeenAt: DateTime.utc(2026, 10, 30, 9, 15),
  isOnline: false,
  isMe: false,
);

/// One item in stock and one sold out.
const List<ProfileMarketItem> fakeProfileItems = [
  ProfileMarketItem(
    id: 'i-1',
    name: 'حديد تسليح ١٢ مم',
    price: Money.halalas(285000),
    inStock: true,
  ),
  ProfileMarketItem(
    id: 'i-2',
    name: 'بلاط بورسلان',
    price: Money.halalas(4500),
    inStock: false,
  ),
];

/// [count] reviews, newest first: even ones about projects, odd ones about
/// orders.
List<ProfileReview> fakeProfileReviews(int count) => [
  for (var i = 0; i < count; i++)
    ProfileReview(
      id: 'r-$i',
      reviewerName: 'عميل $i',
      rating: 5 - i % 3,
      comment: i == 0 ? 'عمل متقن والتزام بالمواعيد' : null,
      isFromProject: i.isEven,
      createdAt: DateTime.utc(2026, 10, 28 - i % 20),
    ),
];

/// A hand-written [ProfileRepository] (APP_ARCHITECTURE.md §16).
///
/// Like the tables, it keeps one profile ([profileResult]), and the writes
/// change it: a new company name or CR number sends a pending or verified
/// business back to unverified, as migration 02's trigger does. Set a
/// result to make that call fail instead. [calls] records the calls in
/// order.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    this.profileResult = const Success(fakeClientProfile),
    this.ratingResult = const Success(ProfileRating(count: 0)),
    this.identityResult = const Success(fakeIdentity),
  });

  Result<MyProfile> profileResult;
  Result<ProfileRating> ratingResult;
  Result<ProfileIdentity?> identityResult;

  /// What a write answers instead of succeeding, e.g. a ConflictFailure.
  Result<String>? uploadResult;
  Result<void>? deleteResult;
  Result<void>? updateUserResult;
  Result<void>? updateBusinessResult;

  Result<List<ProfileCitySuggestion>> searchResult = const Success([]);
  Result<ProfilePlace> placeResult = const Success(
    ProfilePlace(latitude: 24.4672, longitude: 39.6111),
  );
  Result<String?> cityResult = const Success('المدينة المنورة');

  Result<PublicProfile>? publicProfileResult;
  Result<List<ProfileMarketItem>> itemsResult = const Success(fakeProfileItems);

  /// Every review about the user; [getReviews] answers a page of them.
  List<ProfileReview> reviews = fakeProfileReviews(3);

  /// What [getReviews] answers instead of a page.
  Result<List<ProfileReview>>? reviewsResult;

  /// E.g. `getMyProfile`, `uploadAvatar`, `updateUser`,
  /// `deleteAvatar(<path>)`.
  final List<String> calls = [];

  /// What the writes sent, in order.
  final List<ProfileUserWrite> userWrites = [];
  final List<ProfileBusinessChanges> businessWrites = [];

  var _uploads = 0;

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

  @override
  Future<Result<ProfileIdentity?>> getMyIdentity() async {
    calls.add('getMyIdentity');
    return identityResult;
  }

  @override
  Future<Result<String>> uploadAvatar(ProfilePhoto photo) async {
    calls.add('uploadAvatar');
    if (uploadResult case final result?) return result;
    final id = switch (profileResult) {
      Success(:final data) => data.id,
      Failed() => 'unknown',
    };
    _uploads++;
    return Success('$id/avatar_$_uploads.${photo.type.extension}');
  }

  @override
  Future<Result<void>> deleteAvatar(String path) async {
    calls.add('deleteAvatar($path)');
    return deleteResult ?? const Success(null);
  }

  @override
  Future<Result<void>> updateUser(ProfileUserWrite write) async {
    calls.add('updateUser');
    userWrites.add(write);
    if (updateUserResult case final result?) return result;
    if (profileResult case Success(data: final profile)) {
      final path = write.changesAvatar ? write.avatarPath : profile.avatarPath;
      profileResult = Success(
        MyProfile(
          id: profile.id,
          fullName: write.fullName ?? profile.fullName,
          isSuspended: profile.isSuspended,
          avatarPath: path,
          avatarUrl: path == null ? null : 'https://cdn.example/avatars/$path',
          suspensionReason: profile.suspensionReason,
          business: profile.business,
        ),
      );
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> updateBusiness(ProfileBusinessChanges changes) async {
    calls.add('updateBusiness');
    businessWrites.add(changes);
    if (updateBusinessResult case final result?) return result;
    if (profileResult case Success(data: final profile)) {
      final business = profile.business;
      if (business != null) {
        final status = business.verificationStatus;
        final resets =
            (changes.companyName != null || changes.crNumber != null) &&
            (status == VerificationStatus.pending ||
                status == VerificationStatus.verified);
        profileResult = Success(
          MyProfile(
            id: profile.id,
            fullName: profile.fullName,
            isSuspended: profile.isSuspended,
            avatarPath: profile.avatarPath,
            avatarUrl: profile.avatarUrl,
            suspensionReason: profile.suspensionReason,
            business: MyProfileBusiness(
              companyName: changes.companyName ?? business.companyName,
              crNumber: changes.crNumber ?? business.crNumber,
              specializedField:
                  changes.specializedField ?? business.specializedField,
              verificationStatus: resets
                  ? VerificationStatus.unverified
                  : status,
              city: changes.city ?? business.city,
            ),
          ),
        );
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<List<ProfileCitySuggestion>>> searchCities(String query) async {
    calls.add('searchCities($query)');
    return searchResult;
  }

  @override
  Future<Result<ProfilePlace>> getPlace(String placeId) async {
    calls.add('getPlace($placeId)');
    return placeResult;
  }

  @override
  Future<Result<String?>> cityAt(ProfilePlace place) async {
    calls.add('cityAt(${place.latitude}, ${place.longitude})');
    return cityResult;
  }

  @override
  Future<Result<PublicProfile>> getPublicProfile(String userId) async {
    calls.add('getPublicProfile($userId)');
    return publicProfileResult ?? Success(fakePublicProfile);
  }

  @override
  Future<Result<List<ProfileMarketItem>>> getMarketItems(String userId) async {
    calls.add('getMarketItems($userId)');
    return itemsResult;
  }

  @override
  Future<Result<List<ProfileReview>>> getReviews(
    ProfileReviewsQuery query,
  ) async {
    calls.add('getReviews(${query.userId}, ${query.offset})');
    return reviewsResult ??
        Success(
          reviews
              .skip(query.offset)
              .take(ProfileReviewsQuery.pageSize)
              .toList(),
        );
  }
}

/// For tests that open the client's «حسابي», by its route or in the client's
/// navigation, and the edit page from it: the real registrations, with
/// [repository] in place of Supabase. Reset getIt after the test.
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

/// For tests that open a public profile: the real registrations of
/// lib/features/profile/shared/, with [repository] in place of Supabase.
void registerFakePublicProfile([FakeProfileRepository? repository]) {
  registerProfileDependencies(getIt);
  _useRepository(repository ?? FakeProfileRepository());
}

void _useRepository(ProfileRepository repository) {
  getIt
    ..unregister<ProfileRepository>()
    ..registerSingleton<ProfileRepository>(repository);
}
