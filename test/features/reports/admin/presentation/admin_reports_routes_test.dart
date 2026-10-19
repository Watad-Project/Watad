import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_reports_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report.dart';
import 'package:watad/features/reports/admin/domain/entities/admin_report_target.dart';
import 'package:watad/features/reports/admin/presentation/pages/admin_reports_page.dart';
import 'package:watad/features/reports/admin/presentation/widgets/admin_report_card.dart';

import '../../../../helpers/fake_admin_reports_repository.dart';
import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
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
}
