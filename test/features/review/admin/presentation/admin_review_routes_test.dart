import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_image_viewer.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_documents_page.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_page.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_request_card.dart';

import '../../../../helpers/fake_admin_review_repository.dart';
import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeAdminReviewRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeAdminReviewRepository()
      ..requestsResult = const Success([
        AdminReviewRequest(
          businessId: 'b-1',
          companyName: 'مؤسسة البناء الحديث',
          documentCount: 1,
        ),
      ]);
    registerFakeAdminReview(repository);
  });

  tearDown(getIt.reset);

  testWidgets('admin-review opens the queue at its path', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );

    router.goNamed(AdminReviewRoutes.reviewName);
    await tester.pumpAndSettle();
    expect(currentPath(router), AdminReviewRoutes.reviewPath);
    expect(find.byType(AdminReviewPage), findsOneWidget);
    expect(find.byType(AdminReviewRequestCard), findsOneWidget);
  });

  testWidgets('admin-review-documents opens the files of one request', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );

    router.goNamed(
      AdminReviewRoutes.reviewDocumentsName,
      pathParameters: {'businessId': 'b-1'},
    );
    await tester.pumpAndSettle();
    expect(currentPath(router), '/admin/review/b-1');
    expect(
      find.byWidgetPredicate(
        (w) => w is AdminReviewDocumentsPage && w.businessId == 'b-1',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a request opens its files', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminReviewRoutes.reviewName);
    await tester.pumpAndSettle();

    await tester.tap(find.text('مؤسسة البناء الحديث'));
    await tester.pumpAndSettle();
    // Pushed over the queue, so back returns to it.
    expect(find.byType(AdminReviewDocumentsPage), findsOneWidget);
    expect(router.canPop(), isTrue);
  });

  testWidgets('rejecting with «أخرى» sends the details alone', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminReviewRoutes.reviewName);
    await tester.pumpAndSettle();

    await tester.tap(find.text('رفض'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أخرى'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'الختم غير ظاهر');
    await tester.tap(find.text('إرسال الرفض'));
    await tester.pumpAndSettle();

    expect(repository.rejected, [('b-1', 'الختم غير ظاهر')]);
    expect(find.byType(AdminReviewRequestCard), findsNothing);
  });

  testWidgets('rejecting with a listed reason needs no details', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminReviewRoutes.reviewName);
    await tester.pumpAndSettle();

    await tester.tap(find.text('رفض'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المستند منتهي الصلاحية'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('إرسال الرفض'));
    await tester.pumpAndSettle();

    expect(repository.rejected, [('b-1', 'المستند منتهي الصلاحية')]);
  });

  testWidgets('tapping an image opens it full screen', (tester) async {
    repository.documentsResult = Success([
      AdminReviewDocument(
        id: 'doc-1',
        documentType: BusinessDocumentType.commercialRegistration,
        storagePath: 'u-1/license.jpeg',
        createdAt: DateTime.utc(2026, 10, 18),
        url: 'https://example.supabase.co/license.jpeg',
      ),
    ]);
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(
      AdminReviewRoutes.reviewDocumentsName,
      pathParameters: {'businessId': 'b-1'},
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(RegExp('عرض بالحجم الكامل')));
    await tester.pumpAndSettle();
    expect(find.byType(AppImageViewer), findsOneWidget);
  });

  testWidgets('with «أخرى», a tap elsewhere in the sheet closes the keyboard', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminReviewRoutes.reviewName);
    await tester.pumpAndSettle();

    await tester.tap(find.text('رفض'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أخرى'));
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.text('سبب الرفض'));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    // The sheet stays open, with what was written.
    expect(find.text('أخرى'), findsOneWidget);
  });
}
