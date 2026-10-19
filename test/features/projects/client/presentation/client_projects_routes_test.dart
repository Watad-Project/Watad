import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/presentation/pages/client_project_offers_page.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_client_projects_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
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
    createdAt: DateTime.utc(2026, 10, 18),
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
      ..projectsResult = Success([project])
      ..projectResult = Success(project)
      ..offersResult = Success([offer]);
    registerFakeClientProjects(repository);
  });

  tearDown(getIt.reset);

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

  testWidgets('client-projects lists the projects at its path', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(ClientProjectsRoutes.projectsName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ClientProjectsRoutes.projectsPath);
    expect(find.byType(ClientProjectsPage), findsOneWidget);
    expect(find.text('فيلا سكنية'), findsOneWidget);
    expect(find.text('المدينة المنورة — حي الياسمين'), findsOneWidget);
    expect(find.text('موثّق'), findsOneWidget);
    expect(find.text('عرض واحد'), findsOneWidget);

    // A tap opens its offers.
    await tester.tap(find.text('فيلا سكنية'));
    await tester.pumpAndSettle();
    expect(find.byType(ClientProjectOffersPage), findsOneWidget);
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
}
