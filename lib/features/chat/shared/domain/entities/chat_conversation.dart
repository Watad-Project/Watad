import 'package:watad/features/chat/shared/domain/entities/chat_member.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_project_role.dart';

/// The chat's header: who I'm talking to, and its project, if it has one.
class ChatConversation {
  const ChatConversation({
    required this.chatId,
    this.other,
    this.projectId,
    this.projectTitle,
    this.projectRole,
  });

  final String chatId;

  /// Null when the other person closed their account.
  final ChatMember? other;

  final String? projectId;
  final String? projectTitle;

  /// Null when the project isn't mine to open (e.g. an open project I'm
  /// only asking about).
  final ChatProjectRole? projectRole;
}
