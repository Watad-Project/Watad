import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

/// A live event for every new message in any of my chats.
class ChatWatchMyChatsUseCase
    implements UseCase<Stream<Result<void>>, NoParams> {
  const ChatWatchMyChatsUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<Stream<Result<void>>>> call(NoParams params) async =>
      Success(_repository.watchMyChats());
}
