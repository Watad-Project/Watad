import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/router/routes/notifications_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_target.dart';
import 'package:watad/features/notifications/shared/domain/entities/user_notification.dart';
import 'package:watad/features/notifications/shared/presentation/pages/notifications_page.dart';
import 'package:watad/features/notifications/shared/presentation/widgets/notifications_bell.dart';

import '../../../../../helpers/fake_admin_review_repository.dart';
import '../../../../../helpers/fake_app_session.dart';
import '../../../../../helpers/fake_client_home_repository.dart';
import '../../../../../helpers/fake_notifications_repository.dart';
import '../../../../../helpers/fake_splash_repository.dart';
import '../../../../../helpers/pump_router.dart';

void main() {
  late FakeNotificationsRepository repository;

  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
    registerFakeClientHome();
    repository = FakeNotificationsRepository()..unreadResult = const Success(3);
    registerFakeNotifications(repository);
  });

  tearDown(() async {
    await repository.close();
    await getIt.reset();
  });

  /// The client's «الرئيسية» tab, where the bell is lent
  /// (AppSlots.notificationsBell).
  Future<void> openHome(WidgetTester tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(ClientNavigationRoutes.navigationName);
    await tester.pumpAndSettle();
  }

  testWidgets('the client home has the bell with the unread count', (
    tester,
  ) async {
    await openHome(tester);

    expect(find.byType(NotificationsBell), findsOneWidget);
    expect(find.text('٣'), findsOneWidget);
    expect(find.byTooltip('الإشعارات، ٣ إشعارات غير مقروءة'), findsOneWidget);
    expect(repository.pushStarts, 1);
  });

  testWidgets('the admin home has the bell too', (tester) async {
    registerFakeAdminReview(FakeAdminReviewRepository());
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminNavigationRoutes.navigationName);
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsBell), findsOneWidget);
    expect(find.text('٣'), findsOneWidget);
  });

  testWidgets('the bell opens the list', (tester) async {
    await openHome(tester);

    await tester.tap(find.byType(NotificationsBell));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
  });

  testWidgets('a notification arriving in the app shows here, not as a push', (
    tester,
  ) async {
    await openHome(tester);

    repository.arrivals.add(
      Success(
        UserNotification(
          id: 'n-1',
          title: 'عرض جديد',
          body: 'وصلك عرض على مشروعك',
          target: const NotificationTarget(
            route: NotificationsRoutes.notificationsName,
          ),
          createdAt: DateTime.now().toUtc(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عرض جديد: وصلك عرض على مشروعك'), findsOneWidget);
    expect(find.text('٤'), findsOneWidget);
    await tester.tap(find.text('عرض'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
  });

  testWidgets('a tapped push opens where it leads', (tester) async {
    await openHome(tester);

    repository.taps.add(
      const Success(
        NotificationTarget(route: NotificationsRoutes.notificationsName),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsOneWidget);
  });
}
