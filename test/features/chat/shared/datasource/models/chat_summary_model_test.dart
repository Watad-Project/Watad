import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/chat/shared/datasource/models/chat_summary_model.dart';

void main() {
  test('fromJson maps a v_my_chats row with the other member', () {
    final chat = ChatSummaryModel.fromJson(const {
      'id': 'c-1',
      'project_title': 'فيلا سكنية',
      'last_message': '📷 صورة',
      'last_message_sender_id': 'u-2',
      'last_message_at': '2026-11-01T09:00:00+00:00',
      'unread_count': 3,
      'other_members': [
        {'user_id': 'u-2', 'name': 'Omar', 'avatar_path': null},
      ],
      'last_message_is_mine': false,
      'other': {
        'id': 'u-2',
        'display_name': 'مؤسسة الأساس الحديث',
        'avatar_url': null,
        'is_online': true,
        'last_seen_at': '2026-11-01T09:00:00+00:00',
      },
    });

    expect(chat.chatId, 'c-1');
    expect(chat.projectTitle, 'فيلا سكنية');
    expect(chat.lastMessage, '📷 صورة');
    expect(chat.lastMessageAt, DateTime.utc(2026, 11, 1, 9));
    expect(chat.unreadCount, 3);
    expect(chat.lastMessageIsMine, isFalse);
    expect(chat.other?.isOnline, isTrue);
  });

  test('a new chat without messages, with a closed account', () {
    final chat = ChatSummaryModel.fromJson(const {
      'id': 'c-2',
      'project_title': null,
      'last_message': null,
      'last_message_sender_id': null,
      'last_message_at': null,
      'unread_count': 0,
      'other_members': <Object>[],
      'last_message_is_mine': false,
      'other': null,
    });

    expect(chat.lastMessage, isNull);
    expect(chat.lastMessageAt, isNull);
    expect(chat.other, isNull);
    expect(chat.unreadCount, 0);
  });
}
