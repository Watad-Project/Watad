part of 'chat_start_bloc.dart';

sealed class ChatStartState {
  const ChatStartState();
}

final class ChatStartInitial extends ChatStartState {
  const ChatStartInitial();
}

final class ChatStartLoadInProgress extends ChatStartState {
  const ChatStartLoadInProgress();
}

/// The chat to open.
final class ChatStartLoadSuccess extends ChatStartState {
  const ChatStartLoadSuccess(this.chatId);

  final String chatId;
}

final class ChatStartLoadFailure extends ChatStartState {
  const ChatStartLoadFailure(this.failure, this.request);

  final Failure failure;

  /// What to ask again on retry.
  final ChatStartRequest request;
}
