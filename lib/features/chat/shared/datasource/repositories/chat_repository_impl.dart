import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/chat/shared/datasource/remote/chat_remote_data_source.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_conversation.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_message.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_messages_query.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_photo.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._remote);

  final ChatRemoteDataSource _remote;

  @override
  Future<Result<ChatConversation>> getConversation(String chatId) =>
      guardSupabaseCall(() => _remote.getConversation(chatId));

  @override
  Future<Result<List<ChatMessage>>> getMessages(
    String chatId, {
    DateTime? before,
    DateTime? after,
    int limit = ChatMessagesQuery.pageSize,
  }) => guardSupabaseCall(
    () =>
        _remote.getMessages(chatId, limit: limit, before: before, after: after),
  );

  @override
  Future<Result<void>> sendText(String chatId, String text) =>
      guardSupabaseCall(() => _remote.sendText(chatId, text));

  @override
  Future<Result<void>> sendPhoto(
    String chatId,
    ChatPhoto photo, {
    String? caption,
  }) => guardSupabaseCall(
    () => _remote.sendPhoto(chatId, photo, caption: caption),
  );

  @override
  Future<Result<void>> markRead(String chatId) =>
      guardSupabaseCall(() => _remote.markRead(chatId));

  @override
  Stream<Result<void>> watchNewMessages(String chatId) =>
      guardSupabaseStream(_remote.watchNewMessages(chatId));
}
