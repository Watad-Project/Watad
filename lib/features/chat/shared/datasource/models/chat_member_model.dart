import 'package:watad/features/chat/shared/domain/entities/chat_member.dart';

class ChatMemberModel extends ChatMember {
  const ChatMemberModel({
    required super.id,
    required super.name,
    required super.isOnline,
    super.avatarUrl,
    super.lastSeenAt,
  });

  /// Maps the `v_public_profiles` columns selected in
  /// ChatRemoteDataSourceImpl, with `avatar_url`: the public URL of
  /// `avatar_path`.
  factory ChatMemberModel.fromJson(Map<String, dynamic> json) {
    final lastSeenAt = json['last_seen_at'] as String?;
    return ChatMemberModel(
      id: json['id'] as String,
      name: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: lastSeenAt == null ? null : DateTime.parse(lastSeenAt),
    );
  }
}
