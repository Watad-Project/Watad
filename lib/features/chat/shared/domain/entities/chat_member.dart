/// The other person in a chat, with their presence (`v_public_profiles`).
class ChatMember {
  const ChatMember({
    required this.id,
    required this.name,
    required this.isOnline,
    this.avatarUrl,
    this.lastSeenAt,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;

  /// Null when they never opened the app since presence was added.
  final DateTime? lastSeenAt;
}
