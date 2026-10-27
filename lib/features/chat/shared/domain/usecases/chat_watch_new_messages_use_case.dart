import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

/// A live event for every new message in a chat, while it's listened to.
class ChatWatchNewMessagesUseCase
    implements UseCase<Stream<Result<void>>, String> {
  const ChatWatchNewMessagesUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<Stream<Result<void>>>> call(String chatId) async =>
      Success(_repository.watchNewMessages(chatId));
}
