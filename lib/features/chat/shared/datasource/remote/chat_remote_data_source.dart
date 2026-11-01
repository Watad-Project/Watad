import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/chat/shared/datasource/models/chat_conversation_model.dart';
import 'package:watad/features/chat/shared/datasource/models/chat_message_model.dart';
import 'package:watad/features/chat/shared/datasource/models/chat_summary_model.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_photo.dart';

abstract interface class ChatRemoteDataSource {
  Future<List<ChatSummaryModel>> getMyChats();

  /// An event for every message inserted in any of my chats, while
  /// listened to.
  Stream<void> watchMyChats();

  /// The unread total, at once, then again on every new message and every
  /// [unreadRefreshEvery], while listened to.
  Stream<int> watchUnreadTotal();

  /// The chat's id. The database refuses (42501) a project chat that isn't
  /// between its owner and its taker, a business that bid on it, or a
  /// verified business asking about an open project.
  Future<String> startChat(String otherUserId, {String? projectId});

  /// Throws PGRST116 (not found) when I'm not in [chatId].
  Future<ChatConversationModel> getConversation(String chatId);

  /// Newest first.
  Future<List<ChatMessageModel>> getMessages(
    String chatId, {
    required int limit,
    DateTime? before,
    DateTime? after,
  });

  Future<void> sendText(String chatId, String text);

  Future<void> sendPhoto(String chatId, ChatPhoto photo, {String? caption});

  Future<void> markRead(String chatId);

  /// An event for every message inserted in [chatId], while listened to.
  Stream<void> watchNewMessages(String chatId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// How long a photo's signed URL works: long enough to read the chat.
  static const int _signedUrlSeconds = 60 * 60;

  final Random _random = Random.secure();

  /// How often the unread total is read again: reading a chat lowers it,
  /// and that change isn't live (chat_members isn't in realtime).
  static const Duration unreadRefreshEvery = Duration(seconds: 30);

  /// Gives each live channel its own name, so two listeners never share one.
  int _channels = 0;

  @override
  Future<List<ChatSummaryModel>> getMyChats() async {
    final rows = await _client
        .from('v_my_chats')
        .select(
          'id, project_title, last_message, last_message_sender_id, '
          'last_message_at, unread_count, other_members',
        );

    // The other members' names, photos and presence, in one read.
    final otherIds = <String>{for (final row in rows) ?_otherId(row)};
    final profiles = otherIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
              .from('v_public_profiles')
              .select('id, display_name, avatar_path, is_online, last_seen_at')
              .inFilter('id', otherIds.toList());
    final byId = {for (final p in profiles) p['id'] as String: p};

    final myId = _client.auth.currentUser?.id;
    return [
      for (final row in rows)
        ChatSummaryModel.fromJson({
          ...row,
          'last_message_is_mine':
              myId != null && row['last_message_sender_id'] == myId,
          'other': switch (byId[_otherId(row)]) {
            final profile? => {
              ...profile,
              'avatar_url': _avatarUrl(profile['avatar_path']),
            },
            null => null,
          },
        }),
    ];
  }

  @override
  Stream<void> watchMyChats() {
    RealtimeChannel? channel;
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        channel = _messagesChannel(() => controller.add(null));
      },
      onCancel: () async {
        final open = channel;
        channel = null;
        if (open != null) await _client.removeChannel(open);
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  Stream<int> watchUnreadTotal() {
    RealtimeChannel? channel;
    Timer? timer;
    late final StreamController<int> controller;
    // Errors go into the stream (and become Failed in the repository).
    Future<void> read() => _client
        .from('v_my_chats')
        .select('unread_count')
        .then(
          (rows) {
            if (controller.isClosed) return;
            controller.add(
              rows.fold<int>(
                0,
                (sum, row) =>
                    sum + ((row['unread_count'] as num?)?.toInt() ?? 0),
              ),
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          },
        );

    controller = StreamController<int>(
      onListen: () {
        unawaited(read());
        channel = _messagesChannel(read);
        timer = Timer.periodic(unreadRefreshEvery, (_) => read());
      },
      onCancel: () async {
        timer?.cancel();
        final open = channel;
        channel = null;
        if (open != null) await _client.removeChannel(open);
        await controller.close();
      },
    );
    return controller.stream;
  }

  /// Every new message in my chats: Realtime sends only the chats I'm in
  /// (the messages policy).
  RealtimeChannel _messagesChannel(void Function() onMessage) => _client
      .channel('my-chats:${_channels++}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (_) => onMessage(),
      )
      .subscribe();

  /// The other member of a chat of two.
  static String? _otherId(Map<String, dynamic> row) {
    final members = row['other_members'] as List<dynamic>? ?? const [];
    if (members.isEmpty) return null;
    return (members.first as Map<String, dynamic>)['user_id'] as String?;
  }

  @override
  Future<String> startChat(String otherUserId, {String? projectId}) =>
      _client.rpc<String>(
        'start_chat',
        params: {'p_other_user_id': otherUserId, 'p_project_id': projectId},
      );

  @override
  Future<ChatConversationModel> getConversation(String chatId) async {
    final chat = await _client
        .from('v_my_chats')
        .select('id, project_id, project_title, other_members')
        .eq('id', chatId)
        .single();

    // A chat of two: the other member's profile and presence.
    final members = chat['other_members'] as List<dynamic>? ?? const [];
    final otherId = members.isEmpty
        ? null
        : (members.first as Map<String, dynamic>)['user_id'] as String?;
    final other = otherId == null
        ? null
        : await _client
              .from('v_public_profiles')
              .select('id, display_name, avatar_path, is_online, last_seen_at')
              .eq('id', otherId)
              .maybeSingle();

    final projectId = chat['project_id'] as String?;
    final project = projectId == null
        ? null
        : await _client
              .from('v_my_projects')
              .select('my_role')
              .eq('id', projectId)
              .maybeSingle();

    return ChatConversationModel.fromJson({
      ...chat,
      'other': other == null
          ? null
          : {...other, 'avatar_url': _avatarUrl(other['avatar_path'])},
      'my_role': project?['my_role'],
    });
  }

  @override
  Future<List<ChatMessageModel>> getMessages(
    String chatId, {
    required int limit,
    DateTime? before,
    DateTime? after,
  }) async {
    var query = _client
        .from('v_chat_messages')
        .select(
          'id, chat_id, sender_id, sender_name, content, created_at, is_mine, '
          'is_read, attachment_path',
        )
        .eq('chat_id', chatId);
    if (before != null) {
      query = query.lt('created_at', before.toUtc().toIso8601String());
    }
    if (after != null) {
      query = query.gt('created_at', after.toUtc().toIso8601String());
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);

    // The photos are private: each gets a short-lived signed URL.
    final paths = [
      for (final row in rows)
        if (row['attachment_path'] case final String path) path,
    ];
    final urls = <String, String>{};
    if (paths.isNotEmpty) {
      final signed = await _client.storage
          .from('chat-attachments')
          .createSignedUrlsResult(paths, _signedUrlSeconds);
      for (final url in signed) {
        // A file that isn't there shows as a missing photo, not an error.
        if (url case SignedUrlSuccess(:final path, :final signedUrl)) {
          urls[path] = signedUrl;
        }
      }
    }
    return [
      for (final row in rows)
        ChatMessageModel.fromJson({
          ...row,
          'photo_url': urls[row['attachment_path']],
        }),
    ];
  }

  @override
  Future<void> sendText(String chatId, String text) async {
    // Only the INSERT columns allowed on `messages` (ARCHITECTURE.md §3a);
    // sender_id comes from the session.
    await _client.from('messages').insert({'chat_id': chatId, 'content': text});
  }

  @override
  Future<void> sendPhoto(
    String chatId,
    ChatPhoto photo, {
    String? caption,
  }) async {
    // <chat id>/<file id>.<ext>: the only place the bucket and the message
    // take it (ARCHITECTURE.md §8).
    final fileId =
        '${DateTime.now().microsecondsSinceEpoch}'
        '${_random.nextInt(1 << 32).toRadixString(16)}';
    final path = '$chatId/$fileId.${photo.extension}';
    await _client.storage
        .from('chat-attachments')
        .uploadBinary(
          path,
          Uint8List.fromList(photo.bytes),
          fileOptions: FileOptions(contentType: photo.mimeType),
        );
    await _client.from('messages').insert({
      'chat_id': chatId,
      'content': caption,
      'attachment_path': path,
      'attachment_mime': photo.mimeType,
    });
  }

  @override
  Future<void> markRead(String chatId) async {
    await _client.rpc<void>('mark_chat_read', params: {'p_chat_id': chatId});
  }

  @override
  Stream<void> watchNewMessages(String chatId) {
    RealtimeChannel? channel;
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () {
        // Realtime sends only the chats I'm in (the messages policy), and
        // this filter asks only for this one.
        channel = _client
            .channel('chat:$chatId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'chat_id',
                value: chatId,
              ),
              callback: (_) => controller.add(null),
            )
            .subscribe();
      },
      onCancel: () async {
        final open = channel;
        channel = null;
        if (open != null) await _client.removeChannel(open);
        await controller.close();
      },
    );
    return controller.stream;
  }

  /// Avatars live in the public `avatars` bucket.
  String? _avatarUrl(Object? path) => path is String && path.isNotEmpty
      ? _client.storage.from('avatars').getPublicUrl(path)
      : null;
}
