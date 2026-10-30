import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_profile_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/profile/client/presentation/pages/client_profile_page.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_rating.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_profile_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  const suspended = MyProfile(
    id: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
    fullName: 'سارة العتيبي',
    isSuspended: true,
    suspensionReason: 'مخالفة شروط الاستخدام',
  );

  late FakeProfileRepository repository;

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeProfileRepository();
    registerFakeClientProfile(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> openProfile(
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
    router.goNamed(ClientProfileRoutes.profileName);
    await tester.pumpAndSettle();
    return router;
  }

  // The tab is a list that builds what's on screen: scroll to it first.
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(
        finder,
        100,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('client-profile opens «حسابي» at its path', (tester) async {
    repository.ratingResult = const Success(
      ProfileRating(count: 12, average: 4.75),
    );
    final router = await openProfile(tester);

    expect(currentPath(router), ClientProfileRoutes.profilePath);
    expect(find.byType(ClientProfilePage), findsOneWidget);
    expect(find.text('حسابي'), findsOneWidget);
    expect(find.text('سارة العتيبي'), findsOneWidget);
    // «٤٫٨ (١٢)»: the average and the count, in Arabic digits.
    expect(find.textContaining('(١٢)'), findsOneWidget);
    expect(find.text('تعديل الملف الشخصي'), findsOneWidget);
  });

  testWidgets('nobody rated them yet', (tester) async {
    await openProfile(tester);

    expect(find.text('لا تقييمات بعد'), findsOneWidget);
  });

  testWidgets('a row whose screen is not built yet says so', (tester) async {
    await openProfile(tester);

    final orders = find.byKey(const Key('profile_menu_orders'));
    await scrollTo(tester, orders);
    await tester.tap(orders);
    await tester.pump();

    expect(
      find.text('هذه الشاشة قيد الإنشاء، وستتوفر قريبًا.'),
      findsOneWidget,
    );
  });

  testWidgets('a suspended client sees why, and the edit row says so', (
    tester,
  ) async {
    repository.profileResult = const Success(suspended);
    await openProfile(tester);

    expect(find.text('حسابك موقوف'), findsOneWidget);
    expect(find.text('مخالفة شروط الاستخدام'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('profile_menu_edit')));
    expect(find.text('لا يمكن تعديل ملفك أثناء إيقاف حسابك'), findsOneWidget);
  });

  testWidgets('a failed load shows the error, and retry loads it', (
    tester,
  ) async {
    repository.profileResult = const Failed(NetworkFailure());
    await openProfile(tester);

    expect(find.byType(AppErrorView), findsOneWidget);

    repository.profileResult = const Success(fakeClientProfile);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('سارة العتيبي'), findsOneWidget);
  });

  testWidgets('«حسابي» fits large, bold text', (tester) async {
    repository.ratingResult = const Success(
      ProfileRating(count: 12, average: 4.75),
    );
    await openProfile(tester, textScale: largeTextScale, boldText: true);

    await scrollTo(tester, find.byKey(const Key('profile_menu_settings')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a suspended «حسابي» fits large, bold text', (tester) async {
    repository.profileResult = const Success(suspended);
    await openProfile(tester, textScale: largeTextScale, boldText: true);

    await scrollTo(tester, find.byKey(const Key('profile_menu_settings')));
    expect(tester.takeException(), isNull);
  });
}
