/// One message of a chat: a `v_chat_messages` row. It has text, a photo,
/// or both.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.createdAt,
    required this.isMine,
    required this.isRead,
    this.senderName,
    this.content,
    this.photoPath,
    this.photoUrl,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;

  /// Null for a photo sent without text.
  final String? content;

  final DateTime createdAt;

  /// Sent by the signed-in user.
  final bool isMine;

  /// For my message: everyone else read it. For theirs: I read it.
  final bool isRead;

  /// The photo in the private chat-attachments bucket, and a short-lived
  /// signed URL to show it; both null without a photo.
  final String? photoPath;
  final String? photoUrl;

  bool get hasPhoto => photoPath != null;
}
