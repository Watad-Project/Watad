import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/notifications/shared/datasource/local/notifications_push.dart';
import 'package:watad/features/notifications/shared/datasource/models/notification_tap_model.dart';
import 'package:watad/features/notifications/shared/datasource/remote/notifications_remote_data_source.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_tap.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification_change.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote, this._push);

  final NotificationsRemoteDataSource _remote;
  final NotificationsPush _push;

  @override
  Future<Result<List<UserNotification>>> getNotifications() =>
      guardSupabaseCall(_remote.getNotifications);

  @override
  Future<Result<int>> getUnreadCount() =>
      guardSupabaseCall(_remote.getUnreadCount);

  @override
  Future<Result<void>> markRead(List<String>? ids) =>
      guardSupabaseCall(() => _remote.markRead(ids));

  /// The data source's stream is of models: cast it to the entity, or the
  /// guard's transformer (typed for the entity) is refused at run time.
  @override
  Stream<Result<UserNotificationChange>> watchChanges() => guardSupabaseStream(
    _remote.watchChanges().cast<UserNotificationChange>(),
  );

  @override
  Future<Result<void>> startPush() => guardSupabaseCall(() async {
    await _push.start();
    await _push.requestPermission();
  });

  @override
  Stream<Result<NotificationTap>> watchTaps() => guardSupabaseStream(
    _push.taps.map(NotificationTapModel.fromJson).cast<NotificationTap>(),
  );
}
