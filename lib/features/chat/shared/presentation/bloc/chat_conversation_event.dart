part of 'chat_conversation_bloc.dart';

sealed class ChatConversationEvent {
  const ChatConversationEvent();
}

/// The screen opened on [chatId], or retry after an error.
final class ChatConversationOpened extends ChatConversationEvent {
  const ChatConversationOpened(this.chatId);

  final String chatId;
}

/// Read the newest messages again: a new one arrived live, the user pulled
/// to refresh, or the screen's periodic check (for the read ticks).
final class ChatConversationRefreshed extends ChatConversationEvent {
  const ChatConversationRefreshed();
}

/// The user scrolled up to the oldest message shown.
final class ChatOlderMessagesRequested extends ChatConversationEvent {
  const ChatOlderMessagesRequested();
}

/// Send text, a photo, or a photo with [text] as its caption.
final class ChatMessageSent extends ChatConversationEvent {
  const ChatMessageSent({this.text, this.photo});

  final String? text;
  final ChatPhoto? photo;
}

/// «إعادة المحاولة» on a message that failed to send.
final class ChatPendingRetried extends ChatConversationEvent {
  const ChatPendingRetried(this.localId);

  final int localId;
}

/// «حذف» on a message that failed to send.
final class ChatPendingDiscarded extends ChatConversationEvent {
  const ChatPendingDiscarded(this.localId);

  final int localId;
}
