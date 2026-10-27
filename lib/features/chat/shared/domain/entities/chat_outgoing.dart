import 'package:watad/features/chat/shared/domain/entities/chat_photo.dart';

/// What I'm sending: text, a photo with an optional caption, or both.
class ChatOutgoing {
  const ChatOutgoing({required this.chatId, this.text, this.photo});

  final String chatId;
  final String? text;
  final ChatPhoto? photo;
}
