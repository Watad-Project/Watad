import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/evidence_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_export.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_refusal.dart';
import 'package:watad/features/evidence/shared/presentation/pages/evidence_export_page.dart';
import 'package:watad/features/evidence/shared/presentation/pages/evidence_projects_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_evidence_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeEvidenceRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeEvidenceRepository();
    registerFakeEvidence(repository);
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
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(name, pathParameters: pathParameters);
    await tester.pumpAndSettle();
    return router;
  }

  Future<GoRouter> openExport(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) => open(
    tester,
    EvidenceRoutes.evidenceExportName,
    pathParameters: {'projectId': fakeEvidenceProject.id},
    textScale: textScale,
    boldText: boldText,
  );

  testWidgets('evidence-projects lists my contracted projects', (tester) async {
    final router = await open(tester, EvidenceRoutes.evidenceProjectsName);

    expect(currentPath(router), '/evidence');
    expect(find.byType(EvidenceProjectsPage), findsOneWidget);
    expect(find.text('تصدير سجل مشروع'), findsOneWidget);
    expect(find.text('ترميم فيلا في العزيزية'), findsOneWidget);
    expect(find.text('مقاولات الخبر'), findsOneWidget);
    expect(find.text('قيد التنفيذ'), findsOneWidget);
  });

  testWidgets('tapping a project exports it', (tester) async {
    await open(tester, EvidenceRoutes.evidenceProjectsName);

    await tester.tap(find.text('ترميم فيلا في العزيزية'));
    await tester.pumpAndSettle();

    expect(find.byType(EvidenceExportPage), findsOneWidget);
    expect(repository.exports, [fakeEvidenceProject.id]);
  });

  testWidgets('no contracted project shows the empty state', (tester) async {
    repository.projectsResult = const Success([]);
    await open(tester, EvidenceRoutes.evidenceProjectsName);

    expect(
      find.text(
        'لا توجد مشاريع متعاقد عليها بعد. يظهر المشروع هنا بعد قبول عرض عليه.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a list that fails to load offers a retry', (tester) async {
    repository.projectsResult = const Failed(NetworkFailure());
    await open(tester, EvidenceRoutes.evidenceProjectsName);

    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('evidence-export shows what the file holds', (tester) async {
    final router = await openExport(tester);

    expect(currentPath(router), '/evidence/${fakeEvidenceProject.id}');
    expect(find.byType(EvidenceExportPage), findsOneWidget);
    expect(find.text('يوجد اختلاف عن البلوك تشين'), findsOneWidget);
    expect(find.text(fakeProjectEvidence.exportId), findsOneWidget);
    expect(find.text('مشاركة أو حفظ'), findsOneWidget);
    expect(find.text('طباعة'), findsOneWidget);
  });

  testWidgets('a ledger that does not answer makes no file', (tester) async {
    repository.exportResult = const Success(
      EvidenceExportRefused(EvidenceRefusal.ledgerUnavailable),
    );
    await openExport(tester);

    expect(find.textContaining('البلوك تشين لا يستجيب الآن'), findsOneWidget);
    expect(find.text('مشاركة أو حفظ'), findsNothing);

    // A retry asks again.
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(repository.exports, hasLength(2));
  });

  testWidgets('a project not synced yet says to try again shortly', (
    tester,
  ) async {
    repository.exportResult = const Success(
      EvidenceExportRefused(EvidenceRefusal.notOnChainYet),
    );
    await openExport(tester);

    expect(
      find.text(
        'المشروع بانتظار تسجيله على البلوك تشين. حاول مرة أخرى بعد قليل.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('not allowed says so, without a retry', (tester) async {
    repository.exportResult = const Success(
      EvidenceExportRefused(EvidenceRefusal.notAllowed),
    );
    await openExport(tester);

    expect(
      find.textContaining('لا يمكنك تصدير سجل هذا المشروع'),
      findsOneWidget,
    );
    expect(find.text('إعادة المحاولة'), findsNothing);
  });

  testWidgets('the projects page fits large bold text', (tester) async {
    await open(
      tester,
      EvidenceRoutes.evidenceProjectsName,
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(EvidenceProjectsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the export page fits large bold text', (tester) async {
    await openExport(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(EvidenceExportPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
