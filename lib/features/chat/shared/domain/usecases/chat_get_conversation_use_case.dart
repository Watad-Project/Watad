import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_conversation.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

class ChatGetConversationUseCase implements UseCase<ChatConversation, String> {
  const ChatGetConversationUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<ChatConversation>> call(String chatId) =>
      _repository.getConversation(chatId);
}
