import 'package:watad/features/chat/shared/datasource/models/chat_member_model.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_conversation.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_project_role.dart';

class ChatConversationModel extends ChatConversation {
  const ChatConversationModel({
    required super.chatId,
    super.other,
    super.projectId,
    super.projectTitle,
    super.projectRole,
  });

  /// Maps the `v_my_chats` columns selected in ChatRemoteDataSourceImpl,
  /// with `other`: the other member's `v_public_profiles` row (null when
  /// their account is closed), and `my_role`: `v_my_projects.my_role` of
  /// the chat's project (null when it isn't mine to open).
  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final other = json['other'] as Map<String, dynamic>?;
    return ChatConversationModel(
      chatId: json['id'] as String,
      projectId: json['project_id'] as String?,
      projectTitle: json['project_title'] as String?,
      other: other == null ? null : ChatMemberModel.fromJson(other),
      projectRole: switch (json['my_role']) {
        'owner' => ChatProjectRole.owner,
        'taker' => ChatProjectRole.taker,
        _ => null,
      },
    );
  }
}
