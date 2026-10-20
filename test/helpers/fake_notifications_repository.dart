import 'dart:async';

import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification_change.dart';
import 'package:watad/features/notifications/shared/domain/repositories/notifications_repository.dart';
import 'package:watad/features/notifications/shared/notifications_injection.dart';

/// A hand-written [NotificationsRepository]: it answers with the results you
/// set, lets a test send arrivals and taps, and records what was marked read
/// (APP_ARCHITECTURE.md §16).
class FakeNotificationsRepository implements NotificationsRepository {
  Result<List<UserNotification>> listResult = const Success([]);
  Result<int> unreadResult = const Success(0);

  /// Send a change as Realtime would: a new notification, or one read.
  final StreamController<Result<UserNotificationChange>> changes =
      StreamController.broadcast();

  /// Send where a tapped push leads.
  final StreamController<Result<NotificationTarget>> taps =
      StreamController.broadcast();

  /// The calls to markRead: a list of ids, or null for all.
  final List<List<String>?> markedRead = [];
  int pushStarts = 0;

  @override
  Future<Result<List<UserNotification>>> getNotifications() async => listResult;

  @override
  Future<Result<int>> getUnreadCount() async => unreadResult;

  @override
  Future<Result<void>> markRead(List<String>? ids) async {
    markedRead.add(ids);
    return const Success(null);
  }

  @override
  Stream<Result<UserNotificationChange>> watchChanges() => changes.stream;

  /// Send [notification] as just arrived.
  void arrive(UserNotification notification) => changes.add(
    Success(UserNotificationChange(notification: notification, isNew: true)),
  );

  @override
  Future<Result<void>> startPush() async {
    pushStarts++;
    return const Success(null);
  }

  @override
  Stream<Result<NotificationTarget>> watchTaps() => taps.stream;

  /// Call it in tearDown.
  Future<void> close() async {
    await changes.close();
    await taps.close();
  }
}

/// For tests that open the notifications page or a home with the bell: the
/// real registrations, with [repository] in place of Supabase and OneSignal.
/// Reset getIt after the test.
void registerFakeNotifications(FakeNotificationsRepository repository) {
  registerNotificationsDependencies(getIt);
  getIt
    ..unregister<NotificationsRepository>()
    ..registerSingleton<NotificationsRepository>(repository);
}
