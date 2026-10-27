import 'package:watad/core/error/result.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_conversation.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_message.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_messages_query.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_photo.dart';

abstract interface class ChatRepository {
  Future<Result<ChatConversation>> getConversation(String chatId);

  /// Newest first: up to [limit] messages, before [before] or after [after]
  /// when given.
  Future<Result<List<ChatMessage>>> getMessages(
    String chatId, {
    DateTime? before,
    DateTime? after,
    int limit = ChatMessagesQuery.pageSize,
  });

  Future<Result<void>> sendText(String chatId, String text);

  /// Uploads [photo] into the chat's folder, then sends it with [caption].
  Future<Result<void>> sendPhoto(
    String chatId,
    ChatPhoto photo, {
    String? caption,
  });

  Future<Result<void>> markRead(String chatId);

  /// An event each time someone sends a message in [chatId], live.
  Stream<Result<void>> watchNewMessages(String chatId);
}
