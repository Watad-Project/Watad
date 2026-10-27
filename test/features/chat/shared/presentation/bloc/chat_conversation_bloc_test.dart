import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_photo.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_conversation_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_messages_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_mark_read_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_send_message_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_watch_new_messages_use_case.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_conversation_bloc.dart';

import '../../../../../helpers/fake_chat_repository.dart';

ChatConversationBloc _bloc(FakeChatRepository repository) =>
    ChatConversationBloc(
      ChatGetConversationUseCase(repository),
      ChatGetMessagesUseCase(repository),
      ChatSendMessageUseCase(repository),
      ChatMarkReadUseCase(repository),
      ChatWatchNewMessagesUseCase(repository),
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  final t0 = DateTime.utc(2026, 10, 27, 9);

  test('opens: the header, the newest messages, marked read', () async {
    final repository = FakeChatRepository()
      ..messages = [
        fakeChatMessage('m-2', at: t0.add(const Duration(minutes: 1))),
        fakeChatMessage('m-1', at: t0, mine: true, content: 'مرحبا'),
      ];
    final bloc = _bloc(repository)
      ..add(const ChatConversationOpened(fakeChatId));
    await _settle();

    expect(bloc.state.status, ChatConversationStatus.ready);
    expect(bloc.state.conversation?.projectTitle, 'فيلا سكنية');
    expect(bloc.state.messages.map((m) => m.id), ['m-2', 'm-1']);
    expect(bloc.state.hasOlder, isFalse);
    expect(repository.readMarks, 1);
    await bloc.close();
  });

  test('a chat I am not in fails with not found', () async {
    final repository = FakeChatRepository()
      ..conversationResult = fakeChatNotFound;
    final bloc = _bloc(repository)
      ..add(const ChatConversationOpened(fakeChatId));
    await _settle();

    expect(bloc.state.status, ChatConversationStatus.failure);
    expect(bloc.state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('a live message reads the newest again and marks it read', () async {
    final repository = FakeChatRepository()
      ..messages = [fakeChatMessage('m-1', at: t0, content: 'أهلا')];
    final bloc = _bloc(repository)
      ..add(const ChatConversationOpened(fakeChatId));
    await _settle();

    repository.messages = [
      fakeChatMessage(
        'm-2',
        at: t0.add(const Duration(minutes: 1)),
        content: 'جديد',
      ),
      ...repository.messages,
    ];
    repository.live.add(const Success(null));
    await _settle();
    await _settle();

    expect(bloc.state.messages.map((m) => m.id), ['m-2', 'm-1']);
    expect(repository.readMarks, 2);
    await bloc.close();
  });

  test('a refresh updates my read ticks', () async {
    final repository = FakeChatRepository()
      ..messages = [fakeChatMessage('m-1', at: t0, mine: true, content: 'تم؟')];
    final bloc = _bloc(repository)
      ..add(const ChatConversationOpened(fakeChatId));
    await _settle();
    expect(bloc.state.messages.single.isRead, isFalse);

    repository.messages = [
      fakeChatMessage('m-1', at: t0, mine: true, read: true, content: 'تم؟'),
    ];
    bloc.add(const ChatConversationRefreshed());
    await _settle();

    expect(bloc.state.messages.single.isRead, isTrue);
    // Nothing new arrived: no new read mark.
    expect(repository.readMarks, 1);
    await bloc.close();
  });

  test('scrolling up reads the older messages once', () async {
    final repository = FakeChatRepository()
      ..messages = [
        for (var i = 40; i > 0; i--)
          fakeChatMessage(
            'm-$i',
            at: t0.add(Duration(minutes: i)),
            content: '$i',
          ),
      ];
    final bloc = _bloc(repository)
      ..add(const ChatConversationOpened(fakeChatId));
    await _settle();
    expect(bloc.state.messages, hasLength(30));
    expect(bloc.state.hasOlder, isTrue);

    bloc
      ..add(const ChatOlderMessagesRequested())
      ..add(const ChatOlderMessagesRequested());
    await _settle();

    expect(bloc.state.messages, hasLength(40));
    expect(bloc.state.messages.last.id, 'm-1');
    expect(bloc.state.hasOlder, isFalse);
    await bloc.close();
  });

  test('sending shows it pending, then the server copy replaces it', () async {
    final repository = FakeChatRepository();
    final bloc = _bloc(repository)
      ..add(const ChatConversationOpened(fakeChatId));
    await _settle();

    repository.messages = [
      fakeChatMessage('m-1', at: t0, mine: true, content: 'السلام عليكم'),
    ];
    final states = <ChatConversationState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const ChatMessageSent(text: ' السلام عليكم '));
    await _settle();

    expect(states.first.pending.single.text, 'السلام عليكم');
    expect(bloc.state.pending, isEmpty);
    expect(bloc.state.messages.single.id, 'm-1');
    expect(repository.sent, ['text: السلام عليكم']);
    await sub.cancel();
    await bloc.close();
  });

  test('a refused send stays failed, says why, and can be retried', () async {
    final repository = FakeChatRepository()
      ..sendResult = const Failed(PermissionFailure());
    final bloc = _bloc(repository)
      ..add(const ChatConversationOpened(fakeChatId));
    await _settle();

    bloc.add(
      const ChatMessageSent(
        text: 'الواجهة',
        photo: ChatPhoto(bytes: [1], name: 'a.jpg'),
      ),
    );
    await _settle();
    expect(bloc.state.pending.single.hasFailed, isTrue);
    expect(bloc.state.notice?.key, 'chat.send_refused');

    repository.sendResult = const Success(null);
    bloc.add(ChatPendingRetried(bloc.state.pending.single.localId));
    await _settle();
    expect(bloc.state.pending, isEmpty);
    expect(repository.sent, [
      'photo: a.jpg (الواجهة)',
      'photo: a.jpg (الواجهة)',
    ]);
    await bloc.close();
  });

  test('a failed message can be discarded', () async {
    final repository = FakeChatRepository()
      ..sendResult = const Failed(NetworkFailure());
    final bloc = _bloc(repository)
      ..add(const ChatConversationOpened(fakeChatId));
    await _settle();
    bloc.add(const ChatMessageSent(text: 'x'));
    await _settle();
    expect(bloc.state.notice?.key, 'errors.network');

    bloc.add(ChatPendingDiscarded(bloc.state.pending.single.localId));
    await _settle();
    expect(bloc.state.pending, isEmpty);
    await bloc.close();
  });
}
