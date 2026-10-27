import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_start_request.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

/// Opens the chat with someone: the existing one, or a new one. Answers
/// its id.
class ChatStartUseCase implements UseCase<String, ChatStartRequest> {
  const ChatStartUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<String>> call(ChatStartRequest request) =>
      _repository.startChat(request);
}
