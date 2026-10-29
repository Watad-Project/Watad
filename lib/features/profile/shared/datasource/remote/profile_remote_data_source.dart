import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/profile/shared/datasource/models/my_profile_model.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_city_suggestion_model.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_identity_model.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_place_model.dart';
import 'package:watad/features/profile/shared/datasource/models/profile_rating_model.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_business_changes.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_place.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_user_write.dart';

abstract interface class ProfileRemoteDataSource {
  /// The signed-in user's `v_my_profile` row, with their photo's public
  /// URL.
  Future<MyProfileModel> getMyProfile();

  /// The `v_public_profiles` rating of the user with [userId].
  Future<ProfileRatingModel> getRating(String userId);

  /// The signed-in user's `v_my_identity` row, or null when they have none.
  Future<ProfileIdentityModel?> getMyIdentity();

  /// Uploads [photo] to `avatars/<user id>/avatar_<millis>.<ext>` and
  /// returns that path.
  Future<String> uploadAvatar(ProfilePhoto photo);

  /// Deletes the file at [path] from `avatars`.
  Future<void> deleteAvatar(String path);

  /// Updates the signed-in user's `users` row.
  Future<void> updateUser(ProfileUserWrite write);

  /// Updates the signed-in user's `businesses` row.
  Future<void> updateBusiness(ProfileBusinessChanges changes);

  /// The `geocode` Edge Function's search for [query], in Arabic.
  Future<List<ProfileCitySuggestionModel>> searchCities(String query);

  /// The `geocode` Edge Function's place request: where [placeId] is.
  Future<ProfilePlaceModel> getPlace(String placeId);

  /// The `geocode` Edge Function's address of [place], in Arabic: its
  /// `city`, or null when Google knows none there.
  Future<String?> cityAt(ProfilePlace place);
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

  @override
  Future<ProfileIdentityModel?> getMyIdentity() async {
    final row = await _client
        .from('v_my_identity')
        .select('national_id, phone')
        .maybeSingle();
    return row == null ? null : ProfileIdentityModel.fromJson(row);
  }

  @override
  Future<String> uploadAvatar(ProfilePhoto photo) async {
    // A name of our own: `users.avatar_path` takes only letters, digits,
    // dots, dashes and underscores (migration 01), so never the picked
    // file's name.
    final path =
        '${_userId()}/avatar_${DateTime.now().millisecondsSinceEpoch}'
        '.${photo.type.extension}';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          photo.bytes,
          fileOptions: FileOptions(contentType: photo.type.contentType),
        );
    return path;
  }

  @override
  Future<void> deleteAvatar(String path) async {
    await _client.storage.from('avatars').remove([path]);
  }

  @override
  Future<void> updateUser(ProfileUserWrite write) async {
    final userId = _userId();
    // Only the UPDATE columns of ARCHITECTURE.md §3a, and only those that
    // change.
    final rows = await _client
        .from('users')
        .update({
          'full_name': ?write.fullName,
          if (write.changesAvatar) 'avatar_path': write.avatarPath,
        })
        .eq('id', userId)
        .select('id');
    _requireUpdated(rows);
  }

  @override
  Future<void> updateBusiness(ProfileBusinessChanges changes) async {
    final userId = _userId();
    // Only the UPDATE columns of ARCHITECTURE.md §3a, and only those that
    // change. The row's key is `user_id`.
    final rows = await _client
        .from('businesses')
        .update({
          'company_name': ?changes.companyName,
          'cr_number': ?changes.crNumber,
          'specialized_field': ?changes.specializedField,
          'city': ?changes.city,
        })
        .eq('user_id', userId)
        .select('user_id');
    _requireUpdated(rows);
  }

  @override
  Future<List<ProfileCitySuggestionModel>> searchCities(String query) async {
    // Always in Arabic: the cities of saved addresses are, and
    // v_contractors.is_in_my_city compares them exactly.
    final response = await _client.functions.invoke(
      'geocode',
      body: {'query': query, 'language': 'ar'},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['suggestions'] as List<dynamic>? ?? const [])
        .map(
          (row) => ProfileCitySuggestionModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  @override
  Future<ProfilePlaceModel> getPlace(String placeId) async {
    final response = await _client.functions.invoke(
      'geocode',
      body: {'place_id': placeId},
    );
    return ProfilePlaceModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<String?> cityAt(ProfilePlace place) async {
    // The same request the map picker sends for a saved address, so the
    // city is spelled the same way.
    final response = await _client.functions.invoke(
      'geocode',
      body: {'lat': place.latitude, 'lng': place.longitude, 'language': 'ar'},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final city = (data['city'] as String?)?.trim();
    return city == null || city.isEmpty ? null : city;
  }

  /// Avatars live in the public `avatars` bucket.
  String? _avatarUrl(String? path) => path == null || path.isEmpty
      ? null
      : _client.storage.from('avatars').getPublicUrl(path);

  String _userId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('User not authenticated');
    }
    return userId;
  }

  /// An update that RLS filters out changes no row and still answers OK:
  /// that's what a suspended or closed account gets
  /// (`private.is_active_user()`, migration 45). It's the refusal it is.
  static void _requireUpdated(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      throw const PostgrestException(
        message: 'No row was updated',
        code: '42501',
      );
    }
  }
}
