import 'dart:async';

import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/chat/shared/chat_injection.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_conversation.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_member.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_message.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_photo.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_project_role.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_start_request.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';

const String fakeChatId = 'c-1';

final ChatConversation fakeChatConversation = ChatConversation(
  chatId: fakeChatId,
  projectId: 'p-1',
  projectTitle: 'فيلا سكنية',
  projectRole: ChatProjectRole.owner,
  other: ChatMember(
    id: 'u-2',
    name: 'مؤسسة الأساس الحديث',
    isOnline: false,
    lastSeenAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
  ),
);

ChatMessage fakeChatMessage(
  String id, {
  required DateTime at,
  bool mine = false,
  bool read = false,
  String? content,
  String? photoPath,
}) => ChatMessage(
  id: id,
  chatId: fakeChatId,
  senderId: mine ? 'u-1' : 'u-2',
  senderName: mine ? 'Amir' : 'مؤسسة الأساس الحديث',
  createdAt: at,
  isMine: mine,
  isRead: read,
  content: content,
  photoPath: photoPath,
);

/// A hand-written [ChatRepository]: it keeps the chat's messages, answers
/// pages of them newest first, and records what was sent
/// (APP_ARCHITECTURE.md §16).
class FakeChatRepository implements ChatRepository {
  Result<ChatConversation>? conversationResult;

  /// Newest first.
  List<ChatMessage> messages = [];

  /// Answers every read instead of [messages] when set.
  Result<List<ChatMessage>>? messagesResult;

  Result<void> sendResult = const Success(null);

  /// Answers start_chat; the fake chat unless set.
  Result<String> startResult = const Success(fakeChatId);

  /// Who chats were opened with, e.g. `u-2 p-1` or `u-2 -`.
  final List<String> started = [];

  /// What was sent, e.g. `text: hi`, `photo: a.jpg (caption)`.
  final List<String> sent = [];
  int readMarks = 0;

  final StreamController<Result<void>> live = StreamController.broadcast();

  /// Closes [live]; call it in tearDown.
  Future<void> dispose() => live.close();

  @override
  Future<Result<String>> startChat(ChatStartRequest request) async {
    started.add('${request.otherUserId} ${request.projectId ?? '-'}');
    return startResult;
  }

  @override
  Future<Result<ChatConversation>> getConversation(String chatId) async =>
      conversationResult ?? Success(fakeChatConversation);

  @override
  Future<Result<List<ChatMessage>>> getMessages(
    String chatId, {
    DateTime? before,
    DateTime? after,
    int limit = 30,
  }) async {
    if (messagesResult case final result?) return result;
    return Success(
      messages
          .where(
            (m) =>
                (before == null || m.createdAt.isBefore(before)) &&
                (after == null || m.createdAt.isAfter(after)),
          )
          .take(limit)
          .toList(),
    );
  }

  @override
  Future<Result<void>> sendText(String chatId, String text) async {
    sent.add('text: $text');
    return sendResult;
  }

  @override
  Future<Result<void>> sendPhoto(
    String chatId,
    ChatPhoto photo, {
    String? caption,
  }) async {
    sent.add('photo: ${photo.name}${caption == null ? '' : ' ($caption)'}');
    return sendResult;
  }

  @override
  Future<Result<void>> markRead(String chatId) async {
    readMarks++;
    return const Success(null);
  }

  @override
  Stream<Result<void>> watchNewMessages(String chatId) => live.stream;
}

/// Not found, as `.single()` answers for a chat I'm not in.
const Result<ChatConversation> fakeChatNotFound = Failed(NotFoundFailure());

/// For tests that open the chat route: the real registrations, with
/// [repository] in place of Supabase. Reset getIt after the test.
void registerFakeChat(FakeChatRepository repository) {
  registerChatDependencies(getIt);
  getIt
    ..unregister<ChatRepository>()
    ..registerSingleton<ChatRepository>(repository);
}
