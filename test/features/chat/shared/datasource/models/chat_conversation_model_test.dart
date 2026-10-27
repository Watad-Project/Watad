import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/chat/shared/datasource/models/chat_conversation_model.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_project_role.dart';

void main() {
  test('fromJson maps a project chat with the other member', () {
    final chat = ChatConversationModel.fromJson(const {
      'id': 'c-1',
      'project_id': 'p-1',
      'project_title': 'فيلا سكنية',
      'other_members': [
        {'user_id': 'u-2', 'name': 'Omar', 'avatar_path': null},
      ],
      'other': {
        'id': 'u-2',
        'display_name': 'Omar the sheesh',
        'is_online': false,
        'last_seen_at': null,
      },
      'my_role': 'taker',
    });

    expect(chat.chatId, 'c-1');
    expect(chat.projectTitle, 'فيلا سكنية');
    expect(chat.projectRole, ChatProjectRole.taker);
    expect(chat.other?.name, 'Omar the sheesh');
  });

  test('a chat without a project, with a closed account', () {
    final chat = ChatConversationModel.fromJson(const {
      'id': 'c-2',
      'project_id': null,
      'project_title': null,
      'other_members': <Object>[],
      'other': null,
      'my_role': null,
    });

    expect(chat.projectId, isNull);
    expect(chat.projectRole, isNull);
    expect(chat.other, isNull);
  });
}
