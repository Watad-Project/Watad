import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/notifications/shared/datasource/models/user_notification_change_model.dart';
import 'package:watad/features/notifications/shared/datasource/models/user_notification_model.dart';

abstract interface class NotificationsRemoteDataSource {
  /// The newest notifications first, up to a page.
  Future<List<UserNotificationModel>> getNotifications();

  Future<int> getUnreadCount();

  /// Marks [ids] read, or all of the user's when null.
  Future<void> markRead(List<String>? ids);

  /// Each change to the signed-in user's notifications, as it happens: one
  /// inserted, or one read. Every listener shares one Realtime channel.
  Stream<UserNotificationChangeModel> watchChanges();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  NotificationsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// Open while someone listens: the bell, the list.
  late final StreamController<UserNotificationChangeModel> _changes =
      StreamController.broadcast(onListen: _subscribe, onCancel: _unsubscribe);
  RealtimeChannel? _channel;

  /// How many notifications the list shows.
  static const int _pageSize = 50;

  @override
  Future<List<UserNotificationModel>> getNotifications() async {
    final rows = await _client
        .from('v_my_notifications')
        .select('id, title, body, data, read_at, created_at')
        .order('created_at', ascending: false)
        .limit(_pageSize);
    return rows.map(UserNotificationModel.fromJson).toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _client
        .from('v_my_notifications')
        .select('id')
        .isFilter('read_at', null)
        .count(CountOption.exact);
    return response.count;
  }

  @override
  Future<void> markRead(List<String>? ids) async {
    await _client.rpc<int>('mark_notifications_read', params: {'p_ids': ids});
  }

  @override
  Stream<UserNotificationChangeModel> watchChanges() => _changes.stream;

  void _subscribe() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    // Realtime sends the user only their own rows (RLS), and this filter
    // asks only for them.
    _channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final event = switch (payload.eventType) {
              PostgresChangeEvent.insert => 'INSERT',
              PostgresChangeEvent.update => 'UPDATE',
              _ => null,
            };
            if (event == null) return;
            _changes.add(
              UserNotificationChangeModel.fromJson({
                'event': event,
                'record': payload.newRecord,
              }),
            );
          },
        )
        .subscribe();
  }

  Future<void> _unsubscribe() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) await _client.removeChannel(channel);
  }

  /// When the app closes; the channel goes with the last listener anyway.
  Future<void> close() => _changes.close();
}
