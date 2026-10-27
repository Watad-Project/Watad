import 'package:watad/features/chat/shared/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.createdAt,
    required super.isMine,
    required super.isRead,
    super.senderName,
    super.content,
    super.photoPath,
    super.photoUrl,
  });

  /// Maps the `v_chat_messages` columns selected in
  /// ChatRemoteDataSourceImpl, with `photo_url`: the signed URL the data
  /// source made for `attachment_path`.
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String?,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isMine: json['is_mine'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      photoPath: json['attachment_path'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}
