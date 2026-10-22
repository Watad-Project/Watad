import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/router/routes/admin_users_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/users/admin/presentation/pages/admin_user_details_page.dart';
import 'package:watad/features/users/admin/presentation/pages/admin_users_page.dart';
import 'package:watad/features/users/admin/presentation/widgets/admin_user_tile.dart';

import '../../../../helpers/fake_admin_dashboard_repository.dart';
import '../../../../helpers/fake_admin_users_repository.dart';
import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeAdminUsersRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeAdminUsersRepository();
    registerFakeAdminUsers(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> open(
    WidgetTester tester,
    String name, {
    Map<String, String> pathParameters = const {},
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(name, pathParameters: pathParameters);
    await tester.pumpAndSettle();
    return router;
  }

  /// Scrolls the page to [label]'s button, then taps it.
  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.dragUntilVisible(
      find.text(label),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// Scrolls the page until [finder] shows.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('admin-users opens the list at its path, with counts', (
    tester,
  ) async {
    final router = await open(tester, AdminUsersRoutes.usersName);

    expect(currentPath(router), AdminUsersRoutes.usersPath);
    expect(find.byType(AdminUsersPage), findsOneWidget);
    expect(find.byType(AdminUserTile), findsWidgets);
    expect(find.text('الكل ٦'), findsOneWidget);
    expect(find.text('المشرفون ٢'), findsOneWidget);
    // The newest first: the online client.
    expect(find.text('سارة العتيبي'), findsOneWidget);
    expect(find.text('متصل الآن'), findsOneWidget);
  });

  testWidgets('a chip and a search narrow the list', (tester) async {
    await open(tester, AdminUsersRoutes.usersName);

    await tester.tap(find.text('موقوفون ١'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminUserTile), findsOneWidget);
    expect(find.text('فهد القحطاني'), findsOneWidget);

    await tester.tap(find.text('الكل ٦'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'الخبر');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(AdminUserTile), findsOneWidget);
    expect(find.text('خالد الحربي'), findsOneWidget);
    expect(find.text('الكل ١'), findsOneWidget);
  });

  testWidgets('a tap opens the user, and back reloads the list', (
    tester,
  ) async {
    await open(tester, AdminUsersRoutes.usersName);
    final queries = repository.queries.length;

    await tester.tap(find.text('خالد الحربي'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminUserDetailsPage), findsOneWidget);
    // The business, with its pending license.
    expect(find.text('مقاولات الخبر'), findsOneWidget);
    expect(find.text('بانتظار التوثيق'), findsOneWidget);
    expect(find.text('فتح التوثيق'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(AdminUsersPage), findsOneWidget);
    expect(repository.queries.length, queries + 1);
  });

  testWidgets('admin-user-details opens the user at its path', (tester) async {
    final router = await open(
      tester,
      AdminUsersRoutes.userDetailsName,
      pathParameters: {'userId': 'u-client'},
    );

    expect(currentPath(router), '/admin/users/u-client');
    expect(find.byType(AdminUserDetailsPage), findsOneWidget);
    expect(find.text('سارة العتيبي'), findsOneWidget);
    // One kind, and how to reach them.
    expect(find.text('عميل'), findsOneWidget);
    expect(find.text('sara@example.com'), findsOneWidget);
    expect(find.text('+966512345678'), findsOneWidget);
    expect(find.text('1012345678'), findsOneWidget);
    expect(find.text('u-client'), findsOneWidget);
    // Their projects as a client only.
    await tester.dragUntilVisible(
      find.text('مشاريع كعميل'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    expect(find.text('مشاريع كمقاول'), findsNothing);
  });

  testWidgets('a contractor is a contractor only', (tester) async {
    await open(
      tester,
      AdminUsersRoutes.userDetailsName,
      pathParameters: {'userId': 'u-business'},
    );

    expect(find.text('مقاول'), findsOneWidget);
    expect(find.text('عميل'), findsNothing);
    // Never gave a phone or an ID number.
    expect(find.text('غير متوفر'), findsNWidgets(2));
    await tester.dragUntilVisible(
      find.text('مشاريع كمقاول'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    expect(find.text('مشاريع كعميل'), findsNothing);
  });

  testWidgets('suspending asks for a reason first', (tester) async {
    await open(
      tester,
      AdminUsersRoutes.userDetailsName,
      pathParameters: {'userId': 'u-client'},
    );

    await tapButton(tester, 'إيقاف المستخدم');
    expect(find.byType(AppConfirmDialog), findsOneWidget);
    await confirm(tester, 'إيقاف المستخدم');
    // Without a reason nothing is sent.
    expect(repository.calls, isEmpty);

    await tester.enterText(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.byType(TextField),
      ),
      'رسائل مسيئة',
    );
    await confirm(tester, 'إيقاف المستخدم');
    expect(repository.calls, ['suspend u-client: رسائل مسيئة']);
  });

  testWidgets('a suspended user shows why, and can be lifted', (tester) async {
    await open(
      tester,
      AdminUsersRoutes.userDetailsName,
      pathParameters: {'userId': 'u-suspended'},
    );

    await scrollTo(tester, find.text('رسائل مسيئة متكررة'));
    expect(find.text('رسائل مسيئة متكررة'), findsOneWidget);
    expect(find.textContaining('عمر ملا'), findsOneWidget);
    expect(find.text('إيقاف المستخدم'), findsNothing);

    await tapButton(tester, 'رفع الإيقاف');
    await confirm(tester, 'رفع الإيقاف');
    expect(repository.calls, ['unsuspend u-suspended']);
  });

  testWidgets('an admin is not suspended; the role goes first', (tester) async {
    await open(
      tester,
      AdminUsersRoutes.userDetailsName,
      pathParameters: {'userId': 'u-admin'},
    );

    expect(find.text('إيقاف المستخدم'), findsNothing);
    await scrollTo(tester, find.text('لإيقاف مشرف، أزل صلاحيته أولًا.'));
    expect(find.text('لإيقاف مشرف، أزل صلاحيته أولًا.'), findsOneWidget);
    await tapButton(tester, 'إزالة صلاحية المشرف');
    await confirm(tester, 'إزالة صلاحية المشرف');
    expect(repository.calls, ['role u-admin user']);
  });

  testWidgets('your own account offers no action', (tester) async {
    await open(
      tester,
      AdminUsersRoutes.userDetailsName,
      pathParameters: {'userId': 'u-me'},
    );

    const note = 'هذا حسابك: لا يمكنك إيقافه ولا إزالة صلاحيتك.';
    await scrollTo(tester, find.text(note));
    expect(find.text('إيقاف المستخدم'), findsNothing);
    expect(find.text('إزالة صلاحية المشرف'), findsNothing);
    expect(
      find.text('هذا حسابك: لا يمكنك إيقافه ولا إزالة صلاحيتك.'),
      findsOneWidget,
    );
  });

  testWidgets('a closed account is read-only', (tester) async {
    await open(
      tester,
      AdminUsersRoutes.userDetailsName,
      pathParameters: {'userId': 'u-closed'},
    );

    await scrollTo(tester, find.byType(AppStatusCard));
    expect(find.byType(AppStatusCard), findsOneWidget);
    expect(find.text('تعيين كمشرف'), findsNothing);
    expect(find.text('إيقاف المستخدم'), findsNothing);
  });

  testWidgets('a user that does not exist says so', (tester) async {
    await open(
      tester,
      AdminUsersRoutes.userDetailsName,
      pathParameters: {'userId': 'u-none'},
    );

    expect(find.text('لم نجد هذا المستخدم'), findsOneWidget);
  });

  testWidgets('the dashboard opens it from «إدارة المستخدمين»', (tester) async {
    registerFakeAdminDashboard(FakeAdminDashboardRepository());
    // Its «الرئيسية» tab, which connects the button.
    await open(tester, AdminNavigationRoutes.navigationName);

    await tapButton(tester, 'إدارة المستخدمين');
    expect(find.byType(AdminUsersPage), findsOneWidget);
  });

  testWidgets('the list fits large bold text', (tester) async {
    await open(
      tester,
      AdminUsersRoutes.usersName,
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(AdminUsersPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a user page fits large bold text', (tester) async {
    for (final id in ['u-business', 'u-suspended']) {
      await open(
        tester,
        AdminUsersRoutes.userDetailsName,
        pathParameters: {'userId': id},
        textScale: largeTextScale,
        boldText: true,
      );
      expect(find.byType(AdminUserDetailsPage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: id);
    }
  });
}
