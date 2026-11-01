import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

/// How many messages wait for me across all my chats, live: the badge on
/// the «المحادثات» tab.
class ChatWatchUnreadTotalUseCase
    implements UseCase<Stream<Result<int>>, NoParams> {
  const ChatWatchUnreadTotalUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<Stream<Result<int>>>> call(NoParams params) async =>
      Success(_repository.watchUnreadTotal());
}
