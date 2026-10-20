import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/notifications/shared/datasource/local/notifications_push.dart';
import 'package:watad/features/notifications/shared/datasource/models/user_notification_change_model.dart';
import 'package:watad/features/notifications/shared/datasource/models/user_notification_model.dart';
import 'package:watad/features/notifications/shared/datasource/remote/notifications_remote_data_source.dart';
import 'package:watad/features/notifications/shared/datasource/repositories/notifications_repository_impl.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_tap.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification_change.dart';

/// A remote data source whose stream is typed for the model, as the real one.
class _FakeRemote implements NotificationsRemoteDataSource {
  final StreamController<UserNotificationChangeModel> changes =
      StreamController.broadcast();

  @override
  Future<List<UserNotificationModel>> getNotifications() async => const [];

  @override
  Future<int> getUnreadCount() async => 2;

  @override
  Future<void> markRead(List<String>? ids) async {}

  @override
  Stream<UserNotificationChangeModel> watchChanges() => changes.stream;

  Future<void> close() => changes.close();
}

class _FakePush implements NotificationsPush {
  final StreamController<Map<String, dynamic>> tapsController =
      StreamController.broadcast();
  final List<String> calls = [];

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<void> requestPermission() async => calls.add('permission');

  @override
  Stream<Map<String, dynamic>> get taps => tapsController.stream;

  @override
  Future<void> stop() async {}

  Future<void> close() => tapsController.close();
}

void main() {
  late _FakeRemote remote;
  late _FakePush push;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    push = _FakePush();
    repository = NotificationsRepositoryImpl(remote, push);
  });

  tearDown(() async {
    await remote.close();
    await push.close();
  });

  test('a model arriving from the data source comes out as a result', () async {
    final change = UserNotificationChangeModel(
      notification: UserNotificationModel(
        id: 'n-1',
        title: 'عرض جديد',
        body: 'وصلك عرض',
        createdAt: DateTime.utc(2026, 10, 20),
      ),
      isNew: true,
    );
    final first = repository.watchChanges().first;
    remote.changes.add(change);

    expect(
      await first,
      isA<Success<UserNotificationChange>>().having(
        (s) => s.data,
        'data',
        change,
      ),
    );
  });

  test('each tapped push comes out with its notification and data', () async {
    final taps = repository.watchTaps().first;
    push.tapsController.add(const {
      'notification_id': 'n-1',
      'type': 'task_added',
      'project_id': 'p-1',
    });

    expect(
      await taps,
      isA<Success<NotificationTap>>()
          .having((s) => s.data.notificationId, 'notificationId', 'n-1')
          .having((s) => s.data.data, 'data', {
            'type': 'task_added',
            'project_id': 'p-1',
          }),
    );
  });

  test('starting push starts OneSignal, then asks permission', () async {
    expect(await repository.startPush(), isA<Success<void>>());
    expect(push.calls, ['start', 'permission']);
  });

  test('the unread count comes through', () async {
    expect(
      await repository.getUnreadCount(),
      isA<Success<int>>().having((s) => s.data, 'data', 2),
    );
  });
}
