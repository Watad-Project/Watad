import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/chat/shared/datasource/models/chat_member_model.dart';

void main() {
  test('fromJson maps a v_public_profiles row', () {
    final member = ChatMemberModel.fromJson(const {
      'id': 'u-2',
      'display_name': 'مؤسسة الأساس الحديث',
      'avatar_path': 'u-2/avatar.jpg',
      'avatar_url': 'https://example.supabase.co/storage/v1/object/public/avatars/u-2/avatar.jpg',
      'is_online': true,
      'last_seen_at': '2026-10-27T12:00:00+00:00',
    });

    expect(member.name, 'مؤسسة الأساس الحديث');
    expect(member.avatarUrl, endsWith('avatar.jpg'));
    expect(member.isOnline, isTrue);
    expect(member.lastSeenAt, DateTime.utc(2026, 10, 27, 12));
  });

  test('someone who never opened the app has no last seen', () {
    final member = ChatMemberModel.fromJson(const {
      'id': 'u-3',
      'display_name': 'Amir',
      'avatar_path': null,
      'is_online': false,
      'last_seen_at': null,
    });

    expect(member.avatarUrl, isNull);
    expect(member.lastSeenAt, isNull);
  });
}
