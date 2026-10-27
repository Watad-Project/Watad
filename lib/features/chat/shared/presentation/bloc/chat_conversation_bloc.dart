import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_conversation.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_message.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_messages_query.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_outgoing.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_photo.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_conversation_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_messages_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_mark_read_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_send_message_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_watch_new_messages_use_case.dart';

part 'chat_conversation_event.dart';
part 'chat_conversation_state.dart';

/// One conversation: its header, its messages (newest first, older ones
/// page in), live new messages, and what I'm sending. Every message shown
/// comes from the server; one being sent shows as pending until then.
class ChatConversationBloc
    extends Bloc<ChatConversationEvent, ChatConversationState> {
  ChatConversationBloc(
    this._getConversation,
    this._getMessages,
    this._send,
    this._markRead,
    this._watch,
  ) : super(const ChatConversationState()) {
    on<ChatConversationOpened>(_onOpened);
    on<ChatConversationRefreshed>((event, emit) => _readNewest(emit));
    on<ChatOlderMessagesRequested>(_onOlderRequested);
    on<ChatMessageSent>(_onSent);
    on<ChatPendingRetried>(_onRetried);
    on<ChatPendingDiscarded>(
      (event, emit) => emit(
        state.copyWith(
          pending: [
            for (final p in state.pending)
              if (p.localId != event.localId) p,
          ],
        ),
      ),
    );
  }

  final ChatGetConversationUseCase _getConversation;
  final ChatGetMessagesUseCase _getMessages;
  final ChatSendMessageUseCase _send;
  final ChatMarkReadUseCase _markRead;
  final ChatWatchNewMessagesUseCase _watch;

  StreamSubscription<Result<void>>? _live;
  int _nextLocalId = 0;

  Future<void> _onOpened(
    ChatConversationOpened event,
    Emitter<ChatConversationState> emit,
  ) async {
    final chatId = event.chatId;
    emit(
      state.copyWith(
        chatId: () => chatId,
        status: ChatConversationStatus.loading,
        failure: () => null,
      ),
    );
    final conversation = await _getConversation(chatId);
    switch (conversation) {
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ChatConversationStatus.failure,
            failure: () => failure,
          ),
        );
        return;
      case Success(:final data):
        emit(state.copyWith(conversation: () => data));
    }

    final messages = await _getMessages(ChatMessagesQuery(chatId));
    switch (messages) {
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: ChatConversationStatus.failure,
            failure: () => failure,
          ),
        );
        return;
      case Success(:final data):
        emit(
          state.copyWith(
            status: ChatConversationStatus.ready,
            messages: data,
            hasOlder: data.length >= ChatMessagesQuery.pageSize,
          ),
        );
    }
    await _markRead(chatId);

    // New messages, live: each one reads the newest page again.
    if (_live == null) {
      final watch = await _watch(chatId);
      if (watch case Success(:final data)) {
        _live = data.listen((_) => add(const ChatConversationRefreshed()));
      }
    }
  }

  /// Reads the newest page again and merges it in: new messages appear,
  /// and my messages' read ticks follow the other side.
  Future<void> _readNewest(Emitter<ChatConversationState> emit) async {
    final chatId = state.chatId;
    if (chatId == null || state.status != ChatConversationStatus.ready) {
      return;
    }
    final result = await _getMessages(ChatMessagesQuery(chatId));
    if (result case Success(:final data)) {
      final before = state.messages.isEmpty ? null : state.messages.first.id;
      emit(state.copyWith(messages: _merge(state.messages, data)));
      if (state.messages.isNotEmpty && state.messages.first.id != before) {
        await _markRead(chatId);
      }
    }
  }

  Future<void> _onOlderRequested(
    ChatOlderMessagesRequested event,
    Emitter<ChatConversationState> emit,
  ) async {
    final chatId = state.chatId;
    if (chatId == null ||
        !state.hasOlder ||
        state.isLoadingOlder ||
        state.messages.isEmpty) {
      return;
    }
    emit(state.copyWith(isLoadingOlder: true));
    final result = await _getMessages(
      ChatMessagesQuery(chatId, before: state.messages.last.createdAt),
    );
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            messages: _merge(state.messages, data),
            hasOlder: data.length >= ChatMessagesQuery.pageSize,
            isLoadingOlder: false,
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            isLoadingOlder: false,
            notice: () => ChatNotice(failure.messageKey),
          ),
        );
    }
  }

  Future<void> _onSent(
    ChatMessageSent event,
    Emitter<ChatConversationState> emit,
  ) async {
    final text = event.text?.trim();
    if ((text == null || text.isEmpty) && event.photo == null) return;
    final pending = ChatPendingMessage(
      localId: _nextLocalId++,
      text: text == null || text.isEmpty ? null : text,
      photo: event.photo,
    );
    emit(state.copyWith(pending: [...state.pending, pending]));
    await _deliver(pending, emit);
  }

  Future<void> _onRetried(
    ChatPendingRetried event,
    Emitter<ChatConversationState> emit,
  ) async {
    final pending = [
      for (final p in state.pending)
        if (p.localId == event.localId) p,
    ].firstOrNull;
    if (pending == null || !pending.hasFailed) return;
    final retrying = pending.copyWith(hasFailed: false);
    emit(state.copyWith(pending: _replace(state.pending, retrying)));
    await _deliver(retrying, emit);
  }

  /// Sends [pending]; it leaves the list once the server has it, and stays
  /// marked failed (retry or discard) when it doesn't.
  Future<void> _deliver(
    ChatPendingMessage pending,
    Emitter<ChatConversationState> emit,
  ) async {
    final chatId = state.chatId;
    if (chatId == null) return;
    final result = await _send(
      ChatOutgoing(chatId: chatId, text: pending.text, photo: pending.photo),
    );
    switch (result) {
      case Success():
        final messages = await _getMessages(ChatMessagesQuery(chatId));
        emit(
          state.copyWith(
            messages: messages is Success<List<ChatMessage>>
                ? _merge(state.messages, messages.data)
                : null,
            pending: [
              for (final p in state.pending)
                if (p.localId != pending.localId) p,
            ],
          ),
        );
      case Failed(:final failure):
        emit(
          state.copyWith(
            pending: _replace(state.pending, pending.copyWith(hasFailed: true)),
            // The database refuses a suspended or closed account (42501).
            notice: () => ChatNotice(
              failure is PermissionFailure
                  ? 'chat.send_refused'
                  : failure.messageKey,
            ),
          ),
        );
    }
  }

  static List<ChatMessage> _merge(
    List<ChatMessage> shown,
    List<ChatMessage> read,
  ) {
    final byId = {
      for (final m in shown) m.id: m,
      for (final m in read) m.id: m,
    };
    return byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<ChatPendingMessage> _replace(
    List<ChatPendingMessage> all,
    ChatPendingMessage changed,
  ) => [for (final p in all) p.localId == changed.localId ? changed : p];

  @override
  Future<void> close() async {
    await _live?.cancel();
    return super.close();
  }
}
