import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/profile/shared/datasource/models/my_profile_model.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_rating_model.dart';

abstract interface class ProfileRemoteDataSource {
  /// The signed-in user's `v_my_profile` row, with their photo's public
  /// URL.
  Future<MyProfileModel> getMyProfile();

  /// The `v_public_profiles` rating of the user with [userId].
  Future<ProfileRatingModel> getRating(String userId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<MyProfileModel> getMyProfile() async {
    final row = await _client
        .from('v_my_profile')
        .select(
          'id, full_name, avatar_path, is_business, company_name, cr_number, '
          'specialized_field, verification_status, city, is_suspended, '
          'suspension_reason',
        )
        .single();
    return MyProfileModel.fromJson({
      ...row,
      'avatar_url': _avatarUrl(row['avatar_path'] as String?),
    });
  }

  @override
  Future<ProfileRatingModel> getRating(String userId) async {
    final row = await _client
        .from('v_public_profiles')
        .select('rating_avg, rating_count')
        .eq('id', userId)
        .single();
    return ProfileRatingModel.fromJson(row);
  }

  /// Avatars live in the public `avatars` bucket.
  String? _avatarUrl(String? path) => path == null || path.isEmpty
      ? null
      : _client.storage.from('avatars').getPublicUrl(path);
}
