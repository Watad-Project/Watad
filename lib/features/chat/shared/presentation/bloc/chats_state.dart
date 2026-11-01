part of 'chats_bloc.dart';

enum ChatsStatus { initial, loading, success, failure }

final class ChatsState {
  const ChatsState({
    this.status = ChatsStatus.initial,
    this.chats = const [],
    this.failure,
  });

  final ChatsStatus status;

  /// The latest message first; kept while they load again.
  final List<ChatSummary> chats;

  /// Why the chats couldn't load.
  final Failure? failure;

  ChatsState copyWith({
    ChatsStatus? status,
    List<ChatSummary>? chats,
    Failure? Function()? failure,
  }) {
    return ChatsState(
      status: status ?? this.status,
      chats: chats ?? this.chats,
      failure: failure == null ? this.failure : failure(),
    );
  }
}
