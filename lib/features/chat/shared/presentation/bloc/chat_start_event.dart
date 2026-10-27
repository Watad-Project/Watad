part of 'chat_start_bloc.dart';

sealed class ChatStartEvent {
  const ChatStartEvent();
}

/// The page opened, or retry.
final class ChatStartRequested extends ChatStartEvent {
  const ChatStartRequested(this.request);

  final ChatStartRequest request;
}
