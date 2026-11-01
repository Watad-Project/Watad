import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_summary.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_my_chats_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_watch_my_chats_use_case.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chats_bloc.dart';

import '../../../../../helpers/fake_chat_repository.dart';

ChatsBloc _bloc(FakeChatRepository repository) => ChatsBloc(
  ChatGetMyChatsUseCase(repository),
  ChatWatchMyChatsUseCase(repository),
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

ChatSummary _chat(String id, {DateTime? at, int unread = 0}) => ChatSummary(
  chatId: id,
  unreadCount: unread,
  lastMessageIsMine: false,
  lastMessage: at == null ? null : 'مرحبا',
  lastMessageAt: at,
);

void main() {
  test('loads my chats, the latest message first, new ones last', () async {
    final repository = FakeChatRepository()
      ..chatsResult = Success([
        _chat('old', at: DateTime.utc(2026, 10, 1)),
        _chat('new-chat'),
        _chat('latest', at: DateTime.utc(2026, 11, 1), unread: 2),
      ]);
    final bloc = _bloc(repository)..add(const ChatsFetched());
    await _settle();

    expect(bloc.state.status, ChatsStatus.success);
    expect(bloc.state.chats.map((c) => c.chatId), [
      'latest',
      'old',
      'new-chat',
    ]);
    await bloc.close();
    await repository.dispose();
  });

  test('a failed read keeps the failure', () async {
    final repository = FakeChatRepository()
      ..chatsResult = const Failed(NetworkFailure());
    final bloc = _bloc(repository)..add(const ChatsFetched());
    await _settle();

    expect(bloc.state.status, ChatsStatus.failure);
    expect(bloc.state.failure, isA<NetworkFailure>());
    await bloc.close();
    await repository.dispose();
  });

  test('a new message in any chat reads them again', () async {
    final repository = FakeChatRepository()
      ..chatsResult = Success([_chat('c-1', at: DateTime.utc(2026, 10, 1))]);
    final bloc = _bloc(repository)..add(const ChatsFetched());
    await _settle();

    repository.chatsResult = Success([
      _chat('c-1', at: DateTime.utc(2026, 11, 1), unread: 1),
    ]);
    repository.live.add(const Success(null));
    await _settle();
    await _settle();

    expect(bloc.state.chats.single.unreadCount, 1);
    await bloc.close();
    await repository.dispose();
  });
}
