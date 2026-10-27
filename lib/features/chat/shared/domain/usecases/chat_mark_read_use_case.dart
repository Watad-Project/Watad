import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

class ChatMarkReadUseCase implements UseCase<void, String> {
  const ChatMarkReadUseCase(this._repository);

  final ChatRepository _repository;

  @override
  Future<Result<void>> call(String chatId) => _repository.markRead(chatId);
}
