import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_summary.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

/// My chats, the latest message first; new chats without a message last.
class ChatGetMyChatsUseCase implements UseCase<List<ChatSummary>, NoParams> {
  const ChatGetMyChatsUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<List<ChatSummary>>> call(NoParams params) async {
    final result = await _repository.getMyChats();
    return switch (result) {
      Success(:final data) => Success([...data]..sort(_latestFirst)),
      Failed(:final failure) => Failed(failure),
    };
  }

  static int _latestFirst(ChatSummary a, ChatSummary b) {
    final aAt = a.lastMessageAt;
    final bAt = b.lastMessageAt;
    if (aAt == null || bAt == null) {
      return (aAt == null ? 1 : 0) - (bAt == null ? 1 : 0);
    }
    return bAt.compareTo(aAt);
  }
}
