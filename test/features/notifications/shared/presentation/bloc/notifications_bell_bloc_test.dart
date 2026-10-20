import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_tap.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification_change.dart';
import 'package:watad/features/notifications/shared/domain/usecases/get_unread_notifications_count_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/mark_notifications_read_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/start_push_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_notification_changes_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_notification_taps_use_case.dart';
import 'package:watad/features/notifications/shared/presentation/bloc/notifications_bell_bloc.dart';

import '../../../../../helpers/fake_notifications_repository.dart';

void main() {
  late FakeNotificationsRepository repository;

  NotificationsBellBloc buildBloc() => NotificationsBellBloc(
    GetUnreadNotificationsCountUseCase(repository),
    StartPushUseCase(repository),
    WatchNotificationChangesUseCase(repository),
    WatchNotificationTapsUseCase(repository),
    MarkNotificationsReadUseCase(repository),
  );

  final arrival = UserNotification(
    id: 'n-1',
    title: 'عرض جديد',
    body: 'وصلك عرض على مشروعك',
    createdAt: DateTime.utc(2026, 10, 20),
  );

  setUp(() => repository = FakeNotificationsRepository());
  tearDown(() => repository.close());

  test('starting counts the unread ones and starts push', () async {
    repository.unreadResult = const Success(3);
    final bloc = buildBloc()..add(const NotificationsBellStarted());

    final state = await bloc.stream.firstWhere((s) => s.unreadCount == 3);
    expect(state.unreadCount, 3);
    await pumpEventQueue();
    expect(repository.pushStarts, 1);
    await bloc.close();
  });

  test('a failed count keeps zero', () async {
    repository.unreadResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const NotificationsBellStarted());

    await pumpEventQueue();
    expect(bloc.state.unreadCount, 0);
    await bloc.close();
  });

  test('a notification arriving is shown and the bell counts again', () async {
    repository.unreadResult = const Success(1);
    final bloc = buildBloc()..add(const NotificationsBellStarted());
    await bloc.stream.firstWhere((s) => s.unreadCount == 1);
    // Listening has started.
    await pumpEventQueue();

    repository.unreadResult = const Success(2);
    repository.arrive(arrival);
    final state = await bloc.stream.firstWhere(
      (s) => s.arrived != null && s.unreadCount == 2,
    );
    expect(state.arrived, same(arrival));
    await bloc.close();
  });

  test('a notification read elsewhere lowers the count, live', () async {
    repository.unreadResult = const Success(2);
    final bloc = buildBloc()..add(const NotificationsBellStarted());
    await bloc.stream.firstWhere((s) => s.unreadCount == 2);
    await pumpEventQueue();

    repository.unreadResult = const Success(1);
    repository.changes.add(
      Success(
        UserNotificationChange(
          notification: UserNotification(
            id: 'n-1',
            title: 'عرض جديد',
            body: 'وصلك عرض',
            createdAt: DateTime.utc(2026, 10, 20),
            readAt: DateTime.utc(2026, 10, 20, 1),
          ),
          isNew: false,
        ),
      ),
    );
    final state = await bloc.stream.firstWhere((s) => s.unreadCount == 1);
    // A read isn't shown.
    expect(state.arrived, isNull);
    await bloc.close();
  });

  test('a tapped push gives where it leads', () async {
    final bloc = buildBloc()..add(const NotificationsBellStarted());
    await pumpEventQueue();

    const tap = NotificationTap(
      notificationId: 'n-1',
      data: {'type': 'task_added', 'project_id': 'p-1'},
    );
    repository.taps.add(const Success(tap));
    final state = await bloc.stream.firstWhere((s) => s.tapped != null);
    expect(state.tapped, same(tap));
    // Opening the push read it.
    await pumpEventQueue();
    expect(repository.markedRead, [
      ['n-1'],
    ]);
    await bloc.close();
  });

  test('opening a notification\'s toast reads it and counts again', () async {
    repository.unreadResult = const Success(2);
    final bloc = buildBloc()..add(const NotificationsBellStarted());
    await bloc.stream.firstWhere((s) => s.unreadCount == 2);

    repository.unreadResult = const Success(1);
    bloc.add(const NotificationsBellOpened('n-1'));
    await bloc.stream.firstWhere((s) => s.unreadCount == 1);
    expect(repository.markedRead, [
      ['n-1'],
    ]);
    await bloc.close();
  });
}
