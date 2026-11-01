import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/profile/shared/datasource/models/public_profile_model.dart';

void main() {
  test('fromJson maps a v_public_profiles row of a business', () {
    final profile = PublicProfileModel.fromJson(const {
      'id': '3f2a1b4c-5d6e-4f70-8a9b-0c1d2e3f4a5b',
      'display_name': 'مؤسسة البناء المتين ',
      'avatar_path': '3f2a1b4c/avatar_1.jpg',
      'avatar_url':
          'https://x.supabase.co/storage/v1/object/public/avatars/a.jpg',
      'is_deleted': false,
      'member_since': '2026-09-14T08:00:00+00:00',
      'is_business': true,
      'company_name': 'مؤسسة البناء المتين',
      'specialized_field': 'مقاولات عامة',
      'is_verified_business': true,
      'rating_avg': 4.83,
      'rating_count': 12,
      'last_seen_at': '2026-10-30T09:15:00+00:00',
      'is_online': false,
      'is_me': false,
    });

    expect(profile.displayName, 'مؤسسة البناء المتين');
    expect(profile.avatarUrl, endsWith('a.jpg'));
    expect(profile.memberSince, DateTime.utc(2026, 9, 14, 8));
    expect(profile.isBusiness, isTrue);
    expect(profile.specialty, 'مقاولات عامة');
    expect(profile.isVerifiedBusiness, isTrue);
    expect(profile.rating.average, 4.83);
    expect(profile.rating.count, 12);
    expect(profile.lastSeenAt, DateTime.utc(2026, 10, 30, 9, 15));
    expect(profile.isOnline, isFalse);
    expect(profile.isMe, isFalse);
  });

  test('a closed account without a rating', () {
    final profile = PublicProfileModel.fromJson(const {
      'id': 'u-1',
      'display_name': null,
      'is_deleted': true,
      'member_since': null,
      'is_business': false,
      'is_verified_business': false,
      'rating_avg': null,
      'rating_count': 0,
      'last_seen_at': null,
      'is_online': false,
      'is_me': true,
    });

    expect(profile.displayName, '');
    expect(profile.isDeleted, isTrue);
    expect(profile.rating.average, isNull);
    expect(profile.lastSeenAt, isNull);
    expect(profile.isMe, isTrue);
  });
}
