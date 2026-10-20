import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/domain/usecases/get_notifications_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/mark_notifications_read_use_case.dart';
import 'package:watad/features/notifications/shared/domain/usecases/watch_new_notifications_use_case.dart';
import 'package:watad/features/notifications/shared/presentation/bloc/notifications_bloc.dart';

import '../../../../../helpers/fake_notifications_repository.dart';

void main() {
  late FakeNotificationsRepository repository;

  NotificationsBloc buildBloc() => NotificationsBloc(
    GetNotificationsUseCase(repository),
    MarkNotificationsReadUseCase(repository),
    WatchNewNotificationsUseCase(repository),
  );

  final unread = UserNotification(
    id: 'n-1',
    title: 'عرض جديد',
    body: 'وصلك عرض',
    createdAt: DateTime.utc(2026, 10, 20, 8),
  );
  final read = UserNotification(
    id: 'n-2',
    title: 'تم توثيق الصك',
    body: 'نُشر مشروعك',
    createdAt: DateTime.utc(2026, 10, 19),
    readAt: DateTime.utc(2026, 10, 19, 12),
  );

  /// A bloc that has loaded [unread] and [read].
  Future<NotificationsBloc> loadedBloc() async {
    repository.listResult = Success([unread, read]);
    final bloc = buildBloc()..add(const NotificationsFetched());
    await bloc.stream.firstWhere(
      (s) => s.status == NotificationsStatus.success,
    );
    return bloc;
  }

  setUp(() => repository = FakeNotificationsRepository());
  tearDown(() => repository.close());

  test(
    'loads the notifications, newest first, and counts the unread',
    () async {
      final bloc = await loadedBloc();

      expect(bloc.state.notifications, [unread, read]);
      expect(bloc.state.unreadCount, 1);
      await bloc.close();
    },
  );

  test('shows the failure when the list cannot load', () async {
    repository.listResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const NotificationsFetched());

    final state = await bloc.stream.firstWhere(
      (s) => s.status == NotificationsStatus.failure,
    );
    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('opening an unread one marks it read', () async {
    final bloc = await loadedBloc();

    bloc.add(NotificationsOpened(unread));
    final state = await bloc.stream.firstWhere((s) => s.unreadCount == 0);
    expect(state.notifications.first.isRead, isTrue);
    await pumpEventQueue();
    expect(repository.markedRead, [
      ['n-1'],
    ]);
    await bloc.close();
  });

  test('opening a read one sends nothing', () async {
    final bloc = await loadedBloc();

    bloc.add(NotificationsOpened(read));
    await pumpEventQueue();
    expect(repository.markedRead, isEmpty);
    await bloc.close();
  });

  test('«تحديد الكل كمقروء» marks every one read', () async {
    final bloc = await loadedBloc();

    bloc.add(const NotificationsAllRead());
    final state = await bloc.stream.firstWhere((s) => s.unreadCount == 0);
    expect(state.notifications.every((n) => n.isRead), isTrue);
    await pumpEventQueue();
    expect(repository.markedRead, [null]);
    await bloc.close();
  });

  test('a notification arriving goes on top', () async {
    final bloc = await loadedBloc()
      ..add(const NotificationsArrivalsWatched());
    await pumpEventQueue();

    final arrival = UserNotification(
      id: 'n-3',
      title: 'مهمة جديدة',
      body: 'اقترح المقاول مهمة',
      createdAt: DateTime.utc(2026, 10, 20, 9),
    );
    repository.arrivals.add(Success(arrival));
    final state = await bloc.stream.firstWhere(
      (s) => s.notifications.length == 3,
    );
    expect(state.notifications.first, same(arrival));
    expect(state.unreadCount, 2);
    await bloc.close();
  });
}
