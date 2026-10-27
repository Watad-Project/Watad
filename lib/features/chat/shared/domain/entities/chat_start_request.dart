/// Who to chat with, and about which project (none for a chat about an
/// item, an order or a profile).
class ChatStartRequest {
  const ChatStartRequest({required this.otherUserId, this.projectId});

  final String otherUserId;
  final String? projectId;
}
