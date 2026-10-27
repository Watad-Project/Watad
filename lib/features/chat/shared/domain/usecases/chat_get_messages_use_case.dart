import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_message.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_messages_query.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

/// Messages newest first.
class ChatGetMessagesUseCase
    implements UseCase<List<ChatMessage>, ChatMessagesQuery> {
  const ChatGetMessagesUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<List<ChatMessage>>> call(ChatMessagesQuery query) =>
      _repository.getMessages(
        query.chatId,
        before: query.before,
        after: query.after,
        limit: query.limit,
      );
}
