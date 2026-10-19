import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_image_viewer.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/review/admin/domain/entities/admin_deed_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_license_details.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_kind.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_request.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_requester.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_target.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_details_page.dart';
import 'package:watad/features/review/admin/presentation/pages/admin_review_page.dart';
import 'package:watad/features/review/admin/presentation/widgets/admin_review_request_card.dart';

import '../../../../helpers/fake_admin_review_repository.dart';
import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  const licenseTarget = AdminReviewTarget(
    kind: AdminReviewKind.license,
    id: 'b-1',
  );
  const deedTarget = AdminReviewTarget(kind: AdminReviewKind.deed, id: 'p-1');

  late FakeAdminReviewRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeAdminReviewRepository()
      ..requestsResult = const Success([
        AdminReviewRequest(
          kind: AdminReviewKind.license,
          id: 'b-1',
          requesterName: 'مؤسسة البناء الحديث',
        ),
        AdminReviewRequest(
          kind: AdminReviewKind.deed,
          id: 'p-1',
          requesterName: 'سارة القحطاني',
        ),
      ])
      ..details[licenseTarget] = AdminLicenseDetails(
        target: licenseTarget,
        requester: AdminReviewRequester(
          name: 'سالم العتيبي',
          memberSince: DateTime.now().toUtc().subtract(const Duration(days: 3)),
        ),
        companyName: 'مؤسسة البناء الحديث',
        crNumber: '1010123456',
        specializedField: 'مقاولات عامة',
        city: 'المدينة المنورة',
        documents: [
          AdminReviewDocument(
            id: 'doc-1',
            documentType: BusinessDocumentType.commercialRegistration,
            storagePath: 'u-1/license.jpeg',
            createdAt: DateTime.utc(2026, 10, 18),
            url: 'https://example.supabase.co/license.jpeg',
          ),
        ],
      )
      ..details[deedTarget] = AdminDeedDetails(
        target: deedTarget,
        requester: const AdminReviewRequester(name: 'سارة القحطاني'),
        title: 'بناء فيلا',
        description: 'فيلا من دورين في حي العزيزية',
        budget: Money.fromSar(450000),
        city: 'المدينة المنورة',
        district: 'العزيزية',
        photoUrls: const ['https://example.supabase.co/site.jpg'],
        deedUrl: 'https://example.supabase.co/sign/deed.pdf',
        deedPath: 'u-2/deed.pdf',
      );
    registerFakeAdminReview(repository);
  });

  tearDown(getIt.reset);

  Future<void> openQueue(WidgetTester tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(AdminReviewRoutes.reviewName);
    await tester.pumpAndSettle();
  }

  Future<void> openDetails(
    WidgetTester tester,
    AdminReviewTarget target,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(
      AdminReviewRoutes.reviewDetailsName,
      pathParameters: {'kind': target.kind.name, 'id': target.id},
    );
    await tester.pumpAndSettle();
  }

  /// Opens the reject sheet from a request's details.
  Future<void> openRejectSheet(WidgetTester tester) async {
    await openDetails(tester, licenseTarget);
    await tester.tap(find.byKey(const Key('review_reject_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('admin-review opens licenses and deeds in a grid', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );

    router.goNamed(AdminReviewRoutes.reviewName);
    await tester.pumpAndSettle();
    expect(currentPath(router), AdminReviewRoutes.reviewPath);
    expect(find.byType(AdminReviewPage), findsOneWidget);
    expect(find.byType(AdminReviewRequestCard), findsNWidgets(2));
    // Two cards side by side, in one row.
    final license = tester.getCenter(find.byType(AdminReviewRequestCard).first);
    final deed = tester.getCenter(find.byType(AdminReviewRequestCard).last);
    expect(license.dy, deed.dy);
    expect(find.text('رخصة مقاول'), findsOneWidget);
    expect(find.text('صك الملكية'), findsOneWidget);
    expect(find.text('صك ١'), findsOneWidget);
  });

  testWidgets('a card opens only from «التفاصيل»', (tester) async {
    await openQueue(tester);

    await tester.tap(find.text('مؤسسة البناء الحديث'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminReviewDetailsPage), findsNothing);

    await tester.tap(find.text('التفاصيل').first);
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is AdminReviewDetailsPage && w.target == licenseTarget,
      ),
      findsOneWidget,
    );
  });

  testWidgets('a license shows its requester and business', (tester) async {
    await openDetails(tester, licenseTarget);

    expect(find.text('سالم العتيبي'), findsOneWidget);
    expect(find.text('منذ ٣ أيام'), findsOneWidget);
    expect(find.text('مؤسسة البناء الحديث'), findsOneWidget);
    expect(find.text('1010123456'), findsOneWidget);
    expect(find.text('مقاولات عامة'), findsOneWidget);
    expect(find.text('المدينة المنورة'), findsOneWidget);
    expect(find.text('السجل التجاري'), findsOneWidget);
  });

  testWidgets('a deed shows its project, the deed and the photos', (
    tester,
  ) async {
    await openDetails(tester, deedTarget);

    expect(find.text('سارة القحطاني'), findsOneWidget);
    expect(find.text('بناء فيلا'), findsOneWidget);
    expect(find.text('٤٥٠٬٠٠٠ ر.س'), findsOneWidget);
    expect(find.text('العزيزية'), findsOneWidget);
    expect(find.text('فيلا من دورين في حي العزيزية'), findsOneWidget);
    await tester.ensureVisible(find.text('فتح الملف'));
    expect(find.text('فتح الملف'), findsOneWidget);
    await tester.ensureVisible(find.text('صور الموقع'));
    expect(find.text('صور الموقع'), findsOneWidget);
  });

  testWidgets('approving closes the details and the card leaves the grid', (
    tester,
  ) async {
    await openQueue(tester);
    await tester.tap(find.text('التفاصيل').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('review_approve_button')));
    await tester.pumpAndSettle();

    expect(repository.approved, [deedTarget]);
    expect(find.byType(AdminReviewDetailsPage), findsNothing);
    expect(find.byType(AdminReviewRequestCard), findsOneWidget);
    expect(find.text('تم توثيق الصك ونشر المشروع'), findsOneWidget);
  });

  testWidgets('rejecting with «أخرى» sends the details alone', (tester) async {
    await openRejectSheet(tester);

    await tester.tap(find.text('أخرى'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'الختم غير ظاهر');
    await tester.tap(find.text('إرسال الرفض'));
    await tester.pumpAndSettle();

    expect(repository.rejected, [(licenseTarget, 'الختم غير ظاهر')]);
    expect(find.byType(AdminReviewDetailsPage), findsNothing);
  });

  testWidgets('rejecting with a listed reason needs no details', (
    tester,
  ) async {
    await openRejectSheet(tester);

    await tester.tap(find.text('المستند منتهي الصلاحية'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('إرسال الرفض'));
    await tester.pumpAndSettle();

    expect(repository.rejected, [(licenseTarget, 'المستند منتهي الصلاحية')]);
  });

  testWidgets('with «أخرى», a tap elsewhere in the sheet closes the keyboard', (
    tester,
  ) async {
    await openRejectSheet(tester);

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

  testWidgets('tapping an image opens it full screen', (tester) async {
    await openDetails(tester, licenseTarget);

    final image = find.bySemanticsLabel(RegExp('عرض بالحجم الكامل'));
    await tester.ensureVisible(image);
    await tester.pumpAndSettle();
    await tester.tap(image);
    await tester.pumpAndSettle();
    expect(find.byType(AppImageViewer), findsOneWidget);
  });

  testWidgets('a request another admin decided shows an error', (tester) async {
    await openDetails(
      tester,
      const AdminReviewTarget(kind: AdminReviewKind.deed, id: 'gone'),
    );

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.byKey(const Key('review_approve_button')), findsNothing);
  });

  testWidgets('an unknown kind is not found', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
    );
    router.goNamed(
      AdminReviewRoutes.reviewDetailsName,
      pathParameters: {'kind': 'passport', 'id': 'x'},
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppNotFoundView), findsOneWidget);
  });

  testWidgets('the grid and both details fit large, bold text', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.admin),
      textScale: largeTextScale,
      boldText: true,
    );
    router.goNamed(AdminReviewRoutes.reviewName);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final target in [licenseTarget, deedTarget]) {
      router.goNamed(
        AdminReviewRoutes.reviewDetailsName,
        pathParameters: {'kind': target.kind.name, 'id': target.id},
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdminReviewDetailsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
