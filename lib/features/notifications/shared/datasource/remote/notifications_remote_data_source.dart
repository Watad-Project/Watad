import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/notifications/shared/datasource/models/user_notification_model.dart';

abstract interface class NotificationsRemoteDataSource {
  /// The newest notifications first, up to a page.
  Future<List<UserNotificationModel>> getNotifications();

  Future<int> getUnreadCount();

  /// Marks [ids] read, or all of the user's when null.
  Future<void> markRead(List<String>? ids);

  /// Each new notification of the signed-in user, as it is inserted.
  Stream<UserNotificationModel> watchNew();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  const NotificationsRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

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
  Stream<UserNotificationModel> watchNew() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    RealtimeChannel? channel;
    late final StreamController<UserNotificationModel> controller;
    controller = StreamController(
      onListen: () {
        // Realtime sends the user only their own rows (RLS), and this
        // filter asks only for them.
        channel = _client
            .channel('notifications:$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) => controller.add(
                UserNotificationModel.fromJson(payload.newRecord),
              ),
            )
            .subscribe();
      },
      onCancel: () async {
        if (channel case final open?) await _client.removeChannel(open);
        await controller.close();
      },
    );
    return controller.stream;
  }
}
