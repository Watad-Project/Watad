import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_outgoing.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

/// Sends text, a photo, or a photo with a caption. The database takes text
/// of 1 to 4000 characters and JPEG, PNG or WebP photos.
class ChatSendMessageUseCase implements UseCase<void, ChatOutgoing> {
  const ChatSendMessageUseCase(this._repository);

  final ChatRepository _repository;

  /// The longest message the database takes.
  static const int maxLength = 4000;

  @override
  Future<Result<void>> call(ChatOutgoing message) async {
    final text = message.text?.trim();
    final hasText = text != null && text.isNotEmpty;
    if (hasText && text.length > maxLength) {
      return const Failed(ValidationFailure('chat.too_long'));
    }
    final photo = message.photo;
    if (photo == null) {
      if (!hasText) return const Failed(ValidationFailure('chat.empty'));
      return _repository.sendText(message.chatId, text);
    }
    if (photo.mimeType == null) {
      return const Failed(ValidationFailure('chat.photo_type'));
    }
    return _repository.sendPhoto(
      message.chatId,
      photo,
      caption: hasText ? text : null,
    );
  }
}
