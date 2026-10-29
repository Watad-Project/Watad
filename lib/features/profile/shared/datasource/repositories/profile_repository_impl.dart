import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/profile/shared/datasource/remote/profile_remote_data_source.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';
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
}
