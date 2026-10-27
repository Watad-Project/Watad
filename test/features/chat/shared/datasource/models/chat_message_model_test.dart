import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/chat/shared/datasource/models/chat_message_model.dart';

void main() {
  test('fromJson maps a v_chat_messages row with a photo', () {
    final message = ChatMessageModel.fromJson(const {
      'id': 'm-1',
      'chat_id': 'c-1',
      'sender_id': 'u-1',
      'sender_name': 'Amir',
      'content': null,
      'created_at': '2026-10-27T12:00:00.123456+00:00',
      'is_mine': true,
      'is_read': false,
      'attachment_path': 'c-1/1730000000.jpg',
      'photo_url': 'https://example.supabase.co/storage/v1/object/sign/x',
    });

    expect(message.content, isNull);
    expect(message.hasPhoto, isTrue);
    expect(message.photoUrl, startsWith('https://'));
    expect(message.isMine, isTrue);
    expect(message.isRead, isFalse);
    expect(message.createdAt.isUtc, isTrue);
  });

  test('fromJson maps a text message', () {
    final message = ChatMessageModel.fromJson(const {
      'id': 'm-2',
      'chat_id': 'c-1',
      'sender_id': 'u-2',
      'sender_name': null,
      'content': 'السلام عليكم',
      'created_at': '2026-10-27T12:01:00+00:00',
      'is_mine': false,
      'is_read': true,
      'attachment_path': null,
    });

    expect(message.content, 'السلام عليكم');
    expect(message.hasPhoto, isFalse);
    expect(message.photoUrl, isNull);
    expect(message.senderName, isNull);
  });
}
