import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/notifications_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/presentation/pages/notifications_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_notifications_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeNotificationsRepository repository;
  final now = DateTime.now().toUtc();

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeNotificationsRepository()
      ..listResult = Success([
        UserNotification(
          id: 'n-1',
          title: 'عرض جديد',
          body: 'وصلك عرض على مشروعك',
          // Linked below, to the list itself: a route every test has.
          data: const {'type': 'test_linked'},
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        UserNotification(
          id: 'n-2',
          title: 'تم توثيق الصك',
          body: 'نُشر مشروعك',
          // An event no feature links yet.
          data: const {'type': 'test_unlinked'},
          createdAt: now.subtract(const Duration(days: 3)),
          readAt: now.subtract(const Duration(days: 2)),
        ),
      ]);
    registerFakeNotifications(repository);
    AppNotificationLinks.register(
      'test_linked',
      (_) => (name: NotificationsRoutes.notificationsName, pathParameters: {}),
    );
  });

  tearDown(() async {
    AppNotificationLinks.clear();
    await repository.close();
    await getIt.reset();
  });

  Future<void> openList(WidgetTester tester, {double textScale = 1}) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: textScale > 1,
    );
    router.goNamed(NotificationsRoutes.notificationsName);
    await tester.pumpAndSettle();
    expect(currentPath(router), NotificationsRoutes.notificationsPath);
  }

  testWidgets('notifications opens the list at its path', (tester) async {
    await openList(tester);

    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(find.text('الإشعارات'), findsOneWidget);
    expect(find.text('عرض جديد'), findsOneWidget);
    expect(find.text('منذ ساعتين'), findsOneWidget);
    expect(find.text('منذ ٣ أيام'), findsOneWidget);
  });

  testWidgets('a tap marks it read and opens the screen of its event', (
    tester,
  ) async {
    await openList(tester);

    await tester.tap(find.text('عرض جديد'));
    await tester.pumpAndSettle();

    expect(repository.markedRead, [
      ['n-1'],
    ]);
    // Pushed over the list, which stays underneath.
    expect(
      find.byType(NotificationsPage, skipOffstage: false),
      findsNWidgets(2),
    );
  });

  testWidgets('an event no feature links stays on the list', (tester) async {
    await openList(tester);

    await tester.tap(find.text('تم توثيق الصك'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsOneWidget);
    // Already read: nothing to send.
    expect(repository.markedRead, isEmpty);
  });

  testWidgets('«تحديد الكل كمقروء» marks every one read', (tester) async {
    await openList(tester);

    await tester.tap(find.text('تحديد الكل كمقروء'));
    await tester.pumpAndSettle();

    expect(repository.markedRead, [null]);
    expect(find.text('تحديد الكل كمقروء'), findsNothing);
  });

  testWidgets('no notifications yet', (tester) async {
    repository.listResult = const Success([]);
    await openList(tester);

    expect(find.text('لا توجد إشعارات بعد'), findsOneWidget);
  });

  testWidgets('a notification arriving shows on top', (tester) async {
    await openList(tester);

    repository.arrive(
      UserNotification(
        id: 'n-3',
        title: 'مهمة جديدة',
        body: 'اقترح المقاول مهمة',
        createdAt: now,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مهمة جديدة'), findsOneWidget);
    expect(find.text('الآن'), findsOneWidget);
  });

  testWidgets('the list fits large, bold text', (tester) async {
    await openList(tester, textScale: largeTextScale);

    expect(tester.takeException(), isNull);
  });
}
