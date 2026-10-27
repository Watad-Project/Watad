part of 'chat_conversation_bloc.dart';

enum ChatConversationStatus { initial, loading, ready, failure }

/// A message on its way: shown at once, until the server has it.
final class ChatPendingMessage {
  const ChatPendingMessage({
    required this.localId,
    this.text,
    this.photo,
    this.hasFailed = false,
  });

  final int localId;
  final String? text;
  final ChatPhoto? photo;

  /// It didn't send: retry or discard.
  final bool hasFailed;

  ChatPendingMessage copyWith({bool? hasFailed}) => ChatPendingMessage(
    localId: localId,
    text: text,
    photo: photo,
    hasFailed: hasFailed ?? this.hasFailed,
  );
}

/// A message to show once, as a translation key.
final class ChatNotice {
  const ChatNotice(this.key);

  final String key;
}

final class ChatConversationState {
  const ChatConversationState({
    this.chatId,
    this.status = ChatConversationStatus.initial,
    this.conversation,
    this.messages = const [],
    this.hasOlder = false,
    this.isLoadingOlder = false,
    this.pending = const [],
    this.failure,
    this.notice,
  });

  final String? chatId;
  final ChatConversationStatus status;
  final ChatConversation? conversation;

  /// Newest first.
  final List<ChatMessage> messages;

  /// More messages wait above the oldest shown.
  final bool hasOlder;
  final bool isLoadingOlder;

  /// Mine, being sent, oldest first.
  final List<ChatPendingMessage> pending;

  /// Why the conversation couldn't open.
  final Failure? failure;
  final ChatNotice? notice;

  ChatConversationState copyWith({
    String? Function()? chatId,
    ChatConversationStatus? status,
    ChatConversation? Function()? conversation,
    List<ChatMessage>? messages,
    bool? hasOlder,
    bool? isLoadingOlder,
    List<ChatPendingMessage>? pending,
    Failure? Function()? failure,
    ChatNotice? Function()? notice,
  }) {
    return ChatConversationState(
      chatId: chatId == null ? this.chatId : chatId(),
      status: status ?? this.status,
      conversation: conversation == null ? this.conversation : conversation(),
      messages: messages ?? this.messages,
      hasOlder: hasOlder ?? this.hasOlder,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      pending: pending ?? this.pending,
      failure: failure == null ? this.failure : failure(),
      notice: notice == null ? this.notice : notice(),
    );
  }
}
