import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/settings_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_delete_blocker.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_overview.dart';
import 'package:watad/features/settings/shared/presentation/pages/settings_info_page.dart';
import 'package:watad/features/settings/shared/presentation/pages/settings_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_settings_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeSettingsRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeSettingsRepository();
    registerFakeSettings(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> openSettings(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.contractor),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(SettingsRoutes.settingsName);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('settings opens at its path', (tester) async {
    final router = await openSettings(tester);

    expect(currentPath(router), '/settings');
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
    // A contractor without bank details is asked for them.
    expect(find.byKey(const Key('settings_bank_details')), findsOneWidget);
    expect(find.text('مطلوب'), findsOneWidget);
    expect(find.text('الرسائل'), findsOneWidget);
    expect(find.text('الطلبات والسوق'), findsOneWidget);
  });

  testWidgets('a client has no bank details row', (tester) async {
    repository.overviewResult = const Success(
      SettingsOverview(
        isContractor: false,
        hasBankDetails: false,
        notifications: {},
      ),
    );
    await openSettings(tester);

    expect(find.byKey(const Key('settings_bank_details')), findsNothing);
  });

  testWidgets('a switch saves the moment it is tapped', (tester) async {
    await openSettings(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('settings_notify_messages')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.calls, ['messages off']);
  });

  testWidgets('the account notifications stay on', (tester) async {
    await openSettings(tester);

    final locked = tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const Key('settings_notify_account')),
        matching: find.byType(Switch),
      ),
    );
    expect(locked.value, isTrue);
    expect(locked.onChanged, isNull);
  });

  testWidgets('deleting asks first, and says why it is refused', (
    tester,
  ) async {
    repository.blockersResult = const Success({
      SettingsDeleteBlocker.activeProjects,
    });
    await openSettings(tester);

    // The button is at the bottom, past what the list builds at first.
    final delete = find.byKey(const Key('settings_delete_account'));
    await tester.dragUntilVisible(
      delete,
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('حذف الحساب؟'), findsOneWidget);

    await tester.tap(find.text('حذف الحساب').last);
    await tester.pumpAndSettle();
    expect(
      find.text('أكمل مشاريعك قيد التنفيذ قبل حذف الحساب.'),
      findsOneWidget,
    );
    expect(repository.calls, isEmpty);
  });

  testWidgets('settings-info shows a static page at its path', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(
      SettingsRoutes.settingsInfoName,
      pathParameters: {'page': 'privacy'},
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), '/settings/info/privacy');
    expect(find.byType(SettingsInfoPage), findsOneWidget);
    expect(find.text('سياسة الخصوصية'), findsOneWidget);
  });

  testWidgets('settings fit large bold text', (tester) async {
    await openSettings(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the info page fits large bold text', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: largeTextScale,
      boldText: true,
    );
    router.goNamed(
      SettingsRoutes.settingsInfoName,
      pathParameters: {'page': 'terms'},
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsInfoPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
