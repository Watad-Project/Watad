import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_reports_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';
import 'package:watad/features/reports/admin/presentation/pages/admin_report_details_page.dart';
import 'package:watad/features/reports/admin/presentation/pages/admin_reports_page.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_card.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_close_form.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_overview.dart';

import '../../../../helpers/fake_admin_reports_repository.dart';
import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeAdminReportsRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeAdminReportsRepository()
      ..reportsResult = Success([
        AdminReport(
          id: 'r-1',
          type: ReportType.fraud,
          status: ReportStatus.inReview,
          target: AdminReportTarget.marketplaceItem,
          targetId: 'i-1',
          description: 'يبيع حديد تسليح بسعر وهمي ويطلب التحويل مسبقًا',
          reporterName: 'مقاولات الخبر',
          createdAt: DateTime.now().toUtc(),
        ),
      ]);
    registerFakeAdminReports(repository);
  });

  tearDown(getIt.reset);

  Future<void> openReports(WidgetTester tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminReportsRoutes.reportsName);
    await tester.pumpAndSettle();
    expect(currentPath(router), AdminReportsRoutes.reportsPath);
    // It opens on «مفتوحة»; the ticket is in review.
    await tester.tap(find.text('قيد المراجعة ١'));
    await tester.pumpAndSettle();
  }

  Future<GoRouter> openDetails(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(
      AdminReportsRoutes.reportDetailsName,
      pathParameters: {'reportId': 'r-1'},
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('admin-reports opens the reports at its path', (tester) async {
    await openReports(tester);

    expect(find.byType(AdminReportsPage), findsOneWidget);
    expect(find.byType(AdminReportCard), findsOneWidget);
    expect(find.text('احتيال — إعلان'), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget);
  });

  testWidgets('removing a listing asks for a reason first', (tester) async {
    await openReports(tester);

    await tester.tap(find.text('حذف الإعلان'));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsOneWidget);

    // Without a reason nothing is sent.
    await tester.tap(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.text('حذف الإعلان'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, isEmpty);

    await tester.enterText(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.byType(TextField),
      ),
      'إعلان مضلل',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.text('حذف الإعلان'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsNothing);
    expect(repository.calls, [
      'remove i-1: إعلان مضلل',
      'close r-1 resolved: إعلان مضلل',
    ]);
  });

  testWidgets('cancelling sends nothing', (tester) async {
    await openReports(tester);

    await tester.tap(find.text('حذف الإعلان'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsNothing);
    expect(repository.calls, isEmpty);
  });

  testWidgets('a tap elsewhere in the dialog closes the keyboard', (
    tester,
  ) async {
    await openReports(tester);

    await tester.tap(find.text('حذف الإعلان'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('حذف الإعلان؟'));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.byType(AppConfirmDialog), findsOneWidget);
  });

  testWidgets('a tap on a ticket opens its details, and back reloads', (
    tester,
  ) async {
    await openReports(tester);
    final reads = repository.reads;

    await tester.tap(find.text('احتيال — إعلان'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminReportDetailsPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(AdminReportsPage), findsOneWidget);
    // The details read the ticket, then the list was read again.
    expect(repository.reads, reads + 2);
  });

  testWidgets('admin-report-details opens the ticket at its path', (
    tester,
  ) async {
    final router = await openDetails(tester);

    expect(currentPath(router), '/admin/reports/r-1');
    expect(find.byType(AdminReportDetailsPage), findsOneWidget);
    expect(find.byType(AdminReportOverview), findsOneWidget);
    expect(
      find.text('يبيع حديد تسليح بسعر وهمي ويطلب التحويل مسبقًا'),
      findsOneWidget,
    );
    expect(find.byType(AdminReportCloseForm), findsOneWidget);
  });

  testWidgets('closing needs an answer, then sends it', (tester) async {
    await openDetails(tester);

    await tester.ensureVisible(find.text('رفض'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('رفض'));
    await tester.pumpAndSettle();
    expect(find.text('اكتب الرد قبل إغلاق البلاغ'), findsOneWidget);
    expect(repository.calls, isEmpty);

    await tester.enterText(
      find.byKey(const Key('admin_report_note')),
      'السعر صحيح حسب الفاتورة',
    );
    await tester.tap(find.text('رفض'));
    await tester.pumpAndSettle();
    expect(repository.calls, ['close r-1 dismissed: السعر صحيح حسب الفاتورة']);
  });

  testWidgets('a closed ticket is read-only', (tester) async {
    repository.reportResult = Success(
      AdminReport(
        id: 'r-1',
        type: ReportType.technicalIssue,
        status: ReportStatus.resolved,
        description: 'التطبيق يغلق عند رفع الصك',
        assignedAdminName: 'عمر',
        resolutionNote: 'أصلحنا رفع الملفات الكبيرة',
        createdAt: DateTime.utc(2026, 10, 18, 9),
        resolvedAt: DateTime.utc(2026, 10, 19, 9),
      ),
    );
    await openDetails(tester);

    expect(find.byType(AppStatusCard), findsOneWidget);
    expect(find.text('أصلحنا رفع الملفات الكبيرة'), findsOneWidget);
    expect(find.byType(AdminReportCloseForm), findsNothing);
    expect(find.text('إسناد لي'), findsNothing);
  });

  testWidgets('a ticket that does not exist says so', (tester) async {
    repository.reportResult = const Failed(NotFoundFailure());
    await openDetails(tester);

    expect(find.text('لم نجد هذا البلاغ'), findsOneWidget);
  });

  testWidgets('the tickets fit large bold text', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
      textScale: largeTextScale,
      boldText: true,
    );
    router.goNamed(AdminReportsRoutes.reportsName);
    await tester.pumpAndSettle();

    expect(find.byType(AdminReportsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the details fit large bold text', (tester) async {
    await openDetails(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(AdminReportDetailsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
