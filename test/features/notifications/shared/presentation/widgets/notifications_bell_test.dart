import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_top_toast.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/router/routes/notifications_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/notifications/shared/domain/entities/notification_tap.dart';
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

  testWidgets('a notification arriving shows at the top, on any screen', (
    tester,
  ) async {
    await openHome(tester);
    // Another page is open over the home.
    await tester.tap(find.byType(NotificationsBell));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);

    repository
      ..unreadResult = const Success(4)
      ..arrive(
        UserNotification(
          id: 'n-1',
          title: 'عرض جديد',
          body: 'وصلك عرض على مشروعك',
          target: const NotificationTarget(
            route: NotificationsRoutes.notificationsName,
          ),
          createdAt: DateTime.now().toUtc(),
        ),
      );
    await tester.pumpAndSettle();

    expect(find.byType(AppTopToast), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppTopToast),
        matching: find.text('وصلك عرض على مشروعك'),
      ),
      findsOneWidget,
    );
    // The open list shows it too, live.
    expect(
      find.descendant(
        of: find.byType(NotificationsPage),
        matching: find.text('عرض جديد'),
      ),
      findsOneWidget,
    );
    // The bell, under the list, counted again, live.
    expect(find.text('٤', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byType(AppTopToast));
    await tester.pumpAndSettle();
    expect(
      find.byType(NotificationsPage, skipOffstage: false),
      findsNWidgets(2),
    );
    // Opening it read it.
    expect(repository.markedRead, [
      ['n-1'],
    ]);
  });

  testWidgets('a tapped push opens where it leads', (tester) async {
    await openHome(tester);

    repository.taps.add(
      const Success(
        NotificationTap(
          notificationId: 'n-1',
          target: NotificationTarget(
            route: NotificationsRoutes.notificationsName,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(repository.markedRead, [
      ['n-1'],
    ]);
  });
}
