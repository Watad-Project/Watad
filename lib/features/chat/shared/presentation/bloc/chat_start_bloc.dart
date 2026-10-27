import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_start_request.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_start_use_case.dart';

part 'chat_start_event.dart';
part 'chat_start_state.dart';

/// Opens a chat from a «مراسلة» button anywhere in the app: it asks the
/// server for the chat, then the page goes to the conversation.
class ChatStartBloc extends Bloc<ChatStartEvent, ChatStartState> {
  ChatStartBloc(this._start) : super(const ChatStartInitial()) {
    on<ChatStartRequested>(_onRequested);
  }

  final ChatStartUseCase _start;

  Future<void> _onRequested(
    ChatStartRequested event,
    Emitter<ChatStartState> emit,
  ) async {
    emit(const ChatStartLoadInProgress());
    final result = await _start(event.request);
    switch (result) {
      case Success(:final data):
        emit(ChatStartLoadSuccess(data));
      case Failed(:final failure):
        emit(ChatStartLoadFailure(failure, event.request));
    }
  }
}
