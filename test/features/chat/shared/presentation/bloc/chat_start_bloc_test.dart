import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_start_request.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_start_use_case.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_start_bloc.dart';

import '../../../../../helpers/fake_chat_repository.dart';

void main() {
  const request = ChatStartRequest(otherUserId: 'u-2', projectId: 'p-1');

  test('emits LoadInProgress then the chat to open', () async {
    final repository = FakeChatRepository();
    final bloc = ChatStartBloc(ChatStartUseCase(repository));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ChatStartLoadInProgress>(),
        isA<ChatStartLoadSuccess>().having((s) => s.chatId, 'chatId', 'c-1'),
      ]),
    );
    bloc.add(const ChatStartRequested(request));
    await states;
    expect(repository.started, ['u-2 p-1']);
    await bloc.close();
    await repository.dispose();
  });

  test('emits LoadInProgress then the refusal, keeping the request', () async {
    final repository = FakeChatRepository()
      ..startResult = const Failed(PermissionFailure());
    final bloc = ChatStartBloc(ChatStartUseCase(repository));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ChatStartLoadInProgress>(),
        isA<ChatStartLoadFailure>()
            .having((s) => s.failure, 'failure', isA<PermissionFailure>())
            .having((s) => s.request.projectId, 'projectId', 'p-1'),
      ]),
    );
    bloc.add(const ChatStartRequested(request));
    await states;
    await bloc.close();
    await repository.dispose();
  });
}
