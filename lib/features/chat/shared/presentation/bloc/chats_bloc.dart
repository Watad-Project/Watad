import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_summary.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_my_chats_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_watch_my_chats_use_case.dart';

part 'chats_event.dart';
part 'chats_state.dart';

/// «المحادثات»: every chat I'm in, the latest first, read again live when a
/// message arrives in any of them.
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  ChatsBloc(this._getMyChats, this._watchMyChats) : super(const ChatsState()) {
    on<ChatsFetched>(_onFetched);
  }

  final ChatGetMyChatsUseCase _getMyChats;
  final ChatWatchMyChatsUseCase _watchMyChats;

  StreamSubscription<Result<void>>? _live;

  Future<void> _onFetched(ChatsFetched event, Emitter<ChatsState> emit) async {
    emit(state.copyWith(status: ChatsStatus.loading));
    final result = await _getMyChats(const NoParams());
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: ChatsStatus.success,
            chats: data,
            failure: () => null,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(status: ChatsStatus.failure, failure: () => failure),
        );
    }
    if (_live == null) {
      final watch = await _watchMyChats(const NoParams());
      if (watch case Success(:final data)) {
        _live = data.listen((_) => add(const ChatsFetched()));
      }
    }
  }

  @override
  Future<void> close() async {
    await _live?.cancel();
    return super.close();
  }
}
