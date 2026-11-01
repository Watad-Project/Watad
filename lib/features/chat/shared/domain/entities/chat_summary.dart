import 'package:watad/features/chat/shared/domain/entities/chat_member.dart';

/// One row of my chats: a `v_my_chats` row, with the other person's
/// presence.
class ChatSummary {
  const ChatSummary({
    required this.chatId,
    required this.unreadCount,
    required this.lastMessageIsMine,
    this.other,
    this.projectTitle,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String chatId;

  /// Null when the other person closed their account.
  final ChatMember? other;

  /// The chat's project, when it belongs to one.
  final String? projectTitle;

  /// The last message's text, «📷 صورة» for a photo; null in a new chat.
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool lastMessageIsMine;

  /// Their messages I haven't read.
  final int unreadCount;
}
