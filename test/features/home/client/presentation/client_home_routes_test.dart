import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_business_mini_card.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/home/client/domain/entities/client_contractor.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/presentation/pages/client_contractors_page.dart';
import 'package:watad/features/home/client/presentation/pages/client_home_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_client_home_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeClientHomeRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeClientHomeRepository()
      ..contractorsResult = const Success([
        ClientContractor(
          id: 'c-1',
          companyName: 'البناء المتين',
          ratingAvg: 4.8,
          ratingCount: 64,
        ),
        ClientContractor(
          id: 'c-2',
          companyName: 'إتقان للتشييد',
          ratingCount: 0,
        ),
      ]);
    registerFakeClientHome(repository);
  });

  tearDown(getIt.reset);

  Future<void> openHome(WidgetTester tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(ClientHomeRoutes.homeName);
    await tester.pumpAndSettle();
    expect(currentPath(router), ClientHomeRoutes.homePath);
  }

  testWidgets('client-home opens the home at its path', (tester) async {
    await openHome(tester);

    expect(find.byType(ClientHomePage), findsOneWidget);
    expect(find.text('عبدالله الحربي'), findsOneWidget);
    expect(find.text('ابحث عن مقاول أو مادة'), findsOneWidget);
    expect(find.text('انشر مشروعاً'), findsOneWidget);
  });

  testWidgets('verified contractors show their real rating', (tester) async {
    await openHome(tester);

    expect(find.byType(AppBusinessMiniCard), findsNWidgets(2));
    expect(find.text('٤٫٨ · ٦٤ تقييمًا'), findsOneWidget);
    expect(find.text('– · لا تقييمات بعد'), findsOneWidget);
  });

  testWidgets('«جوال موثّق» shows only for a confirmed phone', (tester) async {
    await openHome(tester);
    expect(find.text('جوال موثّق'), findsNothing);
  });

  testWidgets('a confirmed phone shows «جوال موثّق»', (tester) async {
    repository.profileResult = const Success(
      ClientHomeProfile(fullName: 'سارة', isPhoneVerified: true),
    );
    await openHome(tester);
    expect(find.text('جوال موثّق'), findsOneWidget);
  });

  testWidgets('«ابدأ الآن» stays off until the post-project flow exists', (
    tester,
  ) async {
    await openHome(tester);

    final start = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'ابدأ الآن'),
    );
    expect(start.onPressed, isNull);
  });

  testWidgets('no verified contractors yet', (tester) async {
    repository.contractorsResult = const Success([]);
    await openHome(tester);

    expect(find.text('لا يوجد مقاولون موثّقون بعد'), findsOneWidget);
  });

  testWidgets('«الكل» opens every contractor, with the default avatar', (
    tester,
  ) async {
    repository.contractorsPageResult = const Success([
      ClientContractor(
        id: 'c-1',
        companyName: 'البناء المتين',
        ratingAvg: 4.8,
        ratingCount: 64,
      ),
    ]);
    await openHome(tester);

    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();
    expect(find.byType(ClientContractorsPage), findsOneWidget);
    expect(find.text('البناء المتين'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('client-contractors filters by name and rating', (tester) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );
    router.goNamed(ClientHomeRoutes.contractorsName);
    await tester.pumpAndSettle();
    expect(currentPath(router), ClientHomeRoutes.contractorsPath);

    await tester.enterText(find.byType(TextField), 'البناء');
    // The name is sent once typing pauses.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(repository.queries.last.filter.query, 'البناء');

    await tester.tap(find.text('٤ فأكثر'));
    await tester.pumpAndSettle();
    expect(repository.queries.last.filter.minRating, 4);
    expect(repository.queries.last.filter.query, 'البناء');
    expect(find.text('لا يوجد مقاولون يطابقون البحث'), findsOneWidget);
  });
}
