import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_deed_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_post_project_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_deed_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_offers_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_client_projects_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  final project = ClientProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: ProjectStatus.open,
    city: 'المدينة المنورة',
    district: 'حي الياسمين',
    budget: const Money.halalas(45000000),
    pendingOfferCount: 1,
    deedStatus: ClientDeedVerificationStatus.verified,
    createdAt: DateTime.utc(2026, 10, 18),
  );
  final rejected = ClientProject(
    id: 'p-2',
    title: 'ترميم الواجهة',
    status: ProjectStatus.draft,
    city: 'المدينة المنورة',
    pendingOfferCount: 0,
    deedStatus: ClientDeedVerificationStatus.rejected,
    deedRejectionReason: 'الصك غير واضح',
    createdAt: DateTime.utc(2026, 10, 19),
  );
  final offer = ClientProjectOffer(
    id: 'o-1',
    projectId: 'p-1',
    amount: const Money.halalas(46500000),
    status: OfferStatus.pending,
    providerName: 'مؤسسة البناء المتين',
    isProviderVerified: true,
    providerRatingAvg: 4.8,
    providerRatingCount: 12,
    message: 'يشمل التشطيب الخارجي',
    createdAt: DateTime.utc(2026, 10, 18),
  );

  late FakeClientProjectsRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeClientProjectsRepository()
      ..projectsResult = Success([rejected, project])
      ..projectResult = Success(project)
      ..offersResult = Success([offer]);
    registerFakeClientProjects(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> openList(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(ClientProjectsRoutes.projectsName);
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openOffers(WidgetTester tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(
      ClientProjectsRoutes.projectOffersName,
      pathParameters: {'projectId': 'p-1'},
    );
    await tester.pumpAndSettle();
    expect(currentPath(router), '/client/projects/p-1/offers');
  }

  testWidgets('client-post-project opens the post flow at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(ClientProjectsRoutes.postProjectName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ClientProjectsRoutes.postProjectPath);
    expect(find.byType(ClientPostProjectPage), findsOneWidget);
  });

  testWidgets('client-projects lists the projects at its path', (tester) async {
    final router = await openList(tester);

    expect(currentPath(router), ClientProjectsRoutes.projectsPath);
    expect(find.byType(ClientProjectsPage), findsOneWidget);
    expect(find.text('فيلا سكنية'), findsOneWidget);
    expect(find.text('المدينة المنورة — حي الياسمين'), findsOneWidget);
    expect(find.text('موثّق'), findsOneWidget);
    expect(find.text('عرض واحد'), findsOneWidget);
    // A rejected deed says so, with the admin's reason.
    expect(find.text('مرفوض'), findsOneWidget);
    expect(find.text('سبب رفض الصك: الصك غير واضح'), findsOneWidget);

    // A tap opens its offers.
    await tester.tap(find.text('فيلا سكنية'));
    await tester.pumpAndSettle();
    expect(find.byType(ClientProjectOffersPage), findsOneWidget);
  });

  testWidgets('no projects yet offers to post one', (tester) async {
    repository.projectsResult = const Success([]);
    await openList(tester);

    expect(find.text('لم تنشر أي مشروع بعد'), findsOneWidget);
    await tester.tap(find.byKey(const Key('client_projects_post_button')));
    await tester.pumpAndSettle();
    expect(find.byType(ClientPostProjectPage), findsOneWidget);
  });

  testWidgets('client-project-offers shows the offers as in the design', (
    tester,
  ) async {
    await openOffers(tester);

    expect(find.text('فيلا سكنية — حي الياسمين'), findsOneWidget);
    expect(find.text('عرض واحد'), findsOneWidget);
    expect(find.text('الميزانية المعلنة ٤٥٠٬٠٠٠ ر.س'), findsOneWidget);
    expect(find.text('مؤسسة البناء المتين'), findsOneWidget);
    expect(find.text('٤٫٨'), findsOneWidget);
    expect(find.text('يشمل التشطيب الخارجي'), findsOneWidget);
    // The chat has its own issue.
    final message = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'مراسلة'),
    );
    expect(message.onPressed, isNull);
  });

  testWidgets('accepting asks first, then accepts at the amount shown', (
    tester,
  ) async {
    await openOffers(tester);

    await tester.tap(find.widgetWithText(AppButton, 'قبول العرض'));
    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsOneWidget);
    expect(repository.accepted, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(AppConfirmDialog),
        matching: find.text('قبول العرض'),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.accepted, [('o-1', 46500000)]);
  });

  testWidgets('no offers yet', (tester) async {
    repository.offersResult = const Success([]);
    await openOffers(tester);

    expect(find.text('لم تصل عروض على هذا المشروع بعد'), findsOneWidget);
  });

  testWidgets('a rejected deed opens client-project-deed to send a new one', (
    tester,
  ) async {
    repository.projectResult = Success(rejected);
    await openList(tester);

    await tester.tap(find.text('ترميم الواجهة'));
    await tester.pumpAndSettle();
    expect(find.byType(ClientProjectDeedPage), findsOneWidget);
    expect(find.text('الصك غير واضح'), findsOneWidget);
    // Nothing to send before a file is picked.
    final send = find.byKey(const Key('client_project_deed_send'));
    expect(tester.widget<AppButton>(send).onPressed, isNull);

    // The phone's file picker isn't in tests: the bloc gets the file.
    tester
        .element(find.byType(ClientProjectDeedPage))
        .read<ClientProjectDeedBloc>()
        .add(
          const ClientProjectDeedPicked(
            filePath: '/tmp/deed.pdf',
            fileName: 'deed.pdf',
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('تم اختيار الملف: deed.pdf'), findsOneWidget);

    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(repository.replacedDeeds, [('p-2', '/tmp/deed.pdf')]);
    // Sent: back to the list.
    expect(find.byType(ClientProjectDeedPage), findsNothing);
    expect(find.byType(ClientProjectsPage), findsOneWidget);
  });

  testWidgets('a deed that is no longer rejected has nothing to send', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(
      ClientProjectsRoutes.projectDeedName,
      pathParameters: {'projectId': 'p-1'},
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), '/client/projects/p-1/deed');
    expect(find.text('لا يحتاج هذا المشروع إلى صك جديد'), findsOneWidget);
    expect(find.byKey(const Key('client_project_deed_pick')), findsNothing);
  });

  testWidgets('every projects page fits large, bold text', (tester) async {
    final router = await openList(
      tester,
      textScale: largeTextScale,
      boldText: true,
    );
    expect(tester.takeException(), isNull);

    router.goNamed(
      ClientProjectsRoutes.projectOffersName,
      pathParameters: {'projectId': 'p-1'},
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    repository.projectResult = Success(rejected);
    router.goNamed(
      ClientProjectsRoutes.projectDeedName,
      pathParameters: {'projectId': 'p-2'},
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
