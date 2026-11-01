import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/profile/shared/datasource/remote/profile_remote_data_source.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_business_changes.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_city_suggestion.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_identity.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_place.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_user_write.dart';
import 'package:watad/features/profile/shared/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Result<MyProfile>> getMyProfile() =>
      guardSupabaseCall(_remote.getMyProfile);

  @override
  Future<Result<ProfileRating>> getRating(String userId) =>
      guardSupabaseCall(() => _remote.getRating(userId));

  @override
  Future<Result<ProfileIdentity?>> getMyIdentity() =>
      guardSupabaseCall(_remote.getMyIdentity);

  @override
  Future<Result<String>> uploadAvatar(ProfilePhoto photo) =>
      guardSupabaseCall(() => _remote.uploadAvatar(photo));

  @override
  Future<Result<void>> deleteAvatar(String path) =>
      guardSupabaseCall(() => _remote.deleteAvatar(path));

  @override
  Future<Result<void>> updateUser(ProfileUserWrite write) =>
      guardSupabaseCall(() => _remote.updateUser(write));

  @override
  Future<Result<void>> updateBusiness(ProfileBusinessChanges changes) =>
      guardSupabaseCall(() => _remote.updateBusiness(changes));

  @override
  Future<Result<List<ProfileCitySuggestion>>> searchCities(String query) =>
      guardSupabaseCall(() => _remote.searchCities(query));

  @override
  Future<Result<ProfilePlace>> getPlace(String placeId) =>
      guardSupabaseCall(() => _remote.getPlace(placeId));

  @override
  Future<Result<String?>> cityAt(ProfilePlace place) =>
      guardSupabaseCall(() => _remote.cityAt(place));
}
