import 'package:watad/features/chat/shared/datasource/models/chat_member_model.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_summary.dart';

class ChatSummaryModel extends ChatSummary {
  const ChatSummaryModel({
    required super.chatId,
    required super.unreadCount,
    required super.lastMessageIsMine,
    super.other,
    super.projectTitle,
    super.lastMessage,
    super.lastMessageAt,
  });

  /// Maps the `v_my_chats` columns selected in ChatRemoteDataSourceImpl,
  /// with `other`: the other member's `v_public_profiles` row (null when
  /// their account is closed), and `last_message_is_mine`.
  factory ChatSummaryModel.fromJson(Map<String, dynamic> json) {
    final other = json['other'] as Map<String, dynamic>?;
    final lastMessageAt = json['last_message_at'] as String?;
    return ChatSummaryModel(
      chatId: json['id'] as String,
      projectTitle: json['project_title'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: lastMessageAt == null
          ? null
          : DateTime.parse(lastMessageAt),
      lastMessageIsMine: json['last_message_is_mine'] as bool? ?? false,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      other: other == null ? null : ChatMemberModel.fromJson(other),
    );
  }
}
