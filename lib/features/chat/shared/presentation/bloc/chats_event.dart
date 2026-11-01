part of 'chats_bloc.dart';

sealed class ChatsEvent {
  const ChatsEvent();
}

/// Read my chats: when the tab shows, on pull to refresh, back from a
/// conversation, and live when a message arrives.
final class ChatsFetched extends ChatsEvent {
  const ChatsFetched();
}
