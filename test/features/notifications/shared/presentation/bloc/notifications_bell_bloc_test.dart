import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/usecases/get_unread_notifications_count_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/start_push_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_new_notifications_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_notification_taps_use_case.dart';
import 'package:watad/features/notifications/shared/presentation/bloc/notifications_bell_bloc.dart';

import '../../../../../helpers/fake_notifications_repository.dart';

void main() {
  late FakeNotificationsRepository repository;

  NotificationsBellBloc buildBloc() => NotificationsBellBloc(
    GetUnreadNotificationsCountUseCase(repository),
    StartPushUseCase(repository),
    WatchNewNotificationsUseCase(repository),
    WatchNotificationTapsUseCase(repository),
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

  test('a notification arriving adds one and is shown once', () async {
    repository.unreadResult = const Success(1);
    final bloc = buildBloc()..add(const NotificationsBellStarted());
    await bloc.stream.firstWhere((s) => s.unreadCount == 1);
    // Listening has started.
    await pumpEventQueue();

    repository.arrivals.add(Success(arrival));
    final state = await bloc.stream.firstWhere((s) => s.arrived != null);
    expect(state.unreadCount, 2);
    expect(state.arrived, same(arrival));
    await bloc.close();
  });

  test('a tapped push gives where it leads', () async {
    final bloc = buildBloc()..add(const NotificationsBellStarted());
    await pumpEventQueue();

    const target = NotificationTarget(route: 'client-projects');
    repository.taps.add(const Success(target));
    final state = await bloc.stream.firstWhere((s) => s.tapped != null);
    expect(state.tapped, same(target));
    await bloc.close();
  });
}
