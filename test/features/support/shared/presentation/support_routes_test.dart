import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/support_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';
import 'package:watad/features/support/shared/presentation/pages/support_new_report_page.dart';
import 'package:watad/features/support/shared/presentation/pages/support_reports_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/fake_support_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeSupportRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeSupportRepository();
    registerFakeSupport(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> open(
    WidgetTester tester,
    String name, {
    Map<String, String> queryParameters = const {},
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(name, queryParameters: queryParameters);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('support-reports lists my reports at its path', (tester) async {
    final router = await open(tester, SupportRoutes.supportReportsName);

    expect(currentPath(router), '/support');
    expect(find.byType(SupportReportsPage), findsOneWidget);
    expect(find.text('مشكلة في الدفع'), findsOneWidget);
    expect(find.text('تم الحل'), findsOneWidget);
    expect(find.textContaining('عن طلب'), findsOneWidget);
    expect(find.text('تم تحديث حالة الطلب، شكرًا لك'), findsOneWidget);
    expect(find.text('مشكلة تقنية'), findsOneWidget);
    expect(find.text('مفتوح'), findsOneWidget);
  });

  testWidgets('no reports yet says so', (tester) async {
    repository.reportsResult = const Success([]);
    await open(tester, SupportRoutes.supportReportsName);

    expect(find.textContaining('لم ترسل أي بلاغ بعد'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    repository.reportsResult = const Failed(NetworkFailure());
    await open(tester, SupportRoutes.supportReportsName);

    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('a new report is sent, and the list reloads', (tester) async {
    await open(tester, SupportRoutes.supportReportsName);

    await tester.tap(find.byKey(const Key('support_new_report')));
    await tester.pumpAndSettle();
    expect(find.byType(SupportNewReportPage), findsOneWidget);

    await tester.tap(find.text('مشكلة تقنية'));
    await tester.enterText(
      find.byType(TextField),
      'لا تظهر صور المنتجات في السوق',
    );
    await tester.tap(find.byKey(const Key('support_send')));
    await tester.pumpAndSettle();

    final sent = repository.sent.single;
    expect(sent.type, ReportType.technicalIssue);
    expect(sent.description, 'لا تظهر صور المنتجات في السوق');
    expect(sent.target, isNull);
    expect(find.byType(SupportReportsPage), findsOneWidget);
  });

  testWidgets('support-new-report takes its target from the route', (
    tester,
  ) async {
    final router = await open(
      tester,
      SupportRoutes.supportNewReportName,
      queryParameters: {'target': 'item', 'id': 'i-steel'},
    );

    expect(currentPath(router), '/support/new');
    expect(find.text('عن منتج'), findsOneWidget);

    await tester.tap(find.text('احتيال'));
    await tester.enterText(find.byType(TextField), 'الصور مأخوذة من موقع آخر');
    await tester.tap(find.byKey(const Key('support_send')));
    await tester.pumpAndSettle();

    final target = repository.sent.single.target!;
    expect(target.kind, SupportTargetKind.item);
    expect(target.id, 'i-steel');
    // Opened alone, it ends on my reports.
    expect(currentPath(router), '/support');
  });

  testWidgets('nothing is sent without a type and a description', (
    tester,
  ) async {
    await open(tester, SupportRoutes.supportNewReportName);

    await tester.tap(find.byKey(const Key('support_send')));
    await tester.pumpAndSettle();

    expect(find.text('اختر نوع البلاغ'), findsOneWidget);
    expect(find.text('اكتب ٥ أحرف على الأقل'), findsOneWidget);
    expect(repository.sent, isEmpty);
  });

  testWidgets('a refused report stays on the form and says why', (
    tester,
  ) async {
    repository.sendResult = const Failed(PermissionFailure());
    await open(tester, SupportRoutes.supportNewReportName);

    await tester.tap(find.text('أخرى'));
    await tester.enterText(find.byType(TextField), 'وصف المشكلة هنا');
    await tester.tap(find.byKey(const Key('support_send')));
    await tester.pumpAndSettle();

    expect(find.byType(SupportNewReportPage), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('my reports fit large bold text', (tester) async {
    await open(
      tester,
      SupportRoutes.supportReportsName,
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(SupportReportsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the new report fits large bold text', (tester) async {
    await open(
      tester,
      SupportRoutes.supportNewReportName,
      queryParameters: {'target': 'user', 'id': 'u-2'},
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(SupportNewReportPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
