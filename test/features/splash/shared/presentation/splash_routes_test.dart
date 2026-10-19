import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/core/router/routes/onboarding_routes.dart';
import 'package:watad/core/router/routes/splash_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';
import 'package:watad/features/kyc/shared/domain/usecases/get_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/watch_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/presentation/bloc/kyc_status_bloc.dart';
import 'package:watad/features/kyc/shared/presentation/pages/status_page.dart';
import 'package:watad/features/navigation/client/presentation/pages/client_navigation_page.dart';
import 'package:watad/features/navigation/contractor/presentation/pages/contractor_navigation_page.dart';
import 'package:watad/features/onboarding/shared/presentation/pages/onboarding_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';
import 'package:watad/features/splash/shared/presentation/pages/splash_page.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_client_home_repository.dart';
import '../../../../helpers/fake_contractor_dashboard_repository.dart';
import '../../../../helpers/fake_onboarding_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

class _FakeKycRepository implements KycRepository {
  @override
  Future<Result<KycDocument>> getDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]) async => const Success(
    KycDocument(
      id: 'doc-1',
      documentType: BusinessDocumentType.commercialRegistration,
      status: VerificationStatus.pending,
    ),
  );

  @override
  Stream<Result<KycDocument>> watchDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]) => const Stream.empty();
}

void main() {
  late FakeSplashRepository splash;

  setUp(() {
    // The client's navigation opens on its «الرئيسية» tab.
    registerFakeClientHome();
    splash = FakeSplashRepository();
    registerFakeSplashBloc(splash);
    registerFakeOnboardingBloc();
    registerFakeAuthBloc(FakeAuthRepository());
    getIt.registerFactory(
      () => KycStatusBloc(
        GetKycDocumentUseCase(_FakeKycRepository()),
        WatchKycDocumentUseCase(_FakeKycRepository()),
      ),
    );
    registerFakeContractorDashboardTab();
  });

  tearDown(getIt.reset);

  // The splash answers only after its minimum duration (SplashBloc).
  Future<void> waitForSplash(WidgetTester tester) =>
      tester.pump(SplashBloc.defaultMinimumDuration);

  testWidgets('every splash route opens its page at its path', (tester) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(SplashRoutes.splashName);
    await tester.pumpAndSettle();
    expect(currentPath(router), SplashRoutes.splashPath);
    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('goes to the onboarding until it has been seen', (tester) async {
    final router = await pumpAppRouter(tester);

    splash.answer(const Success(SplashDestination.onboarding));
    await waitForSplash(tester);
    // Not pumpAndSettle: the slide animation loops.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(currentPath(router), OnboardingRoutes.onboardingPath);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('goes to the login page once the onboarding is seen', (
    tester,
  ) async {
    final router = await pumpAppRouter(tester);

    splash.answer(const Success(SplashDestination.login));
    await waitForSplash(tester);
    await tester.pumpAndSettle();
    expect(currentPath(router), AuthRoutes.loginPath);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets('a signed-in user goes on to their role\'s navigation', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
    );

    splash.answer(const Success(SplashDestination.home));
    await waitForSplash(tester);
    await tester.pumpAndSettle();
    expect(currentPath(router), ClientNavigationRoutes.navigationPath);
    expect(find.byType(ClientNavigationPage), findsOneWidget);
    expect(router.canPop(), isFalse);
  });

  testWidgets(
    'a signed-in contractor pending KYC is redirected to KYC status page',
    (tester) async {
      final router = await pumpAppRouter(
        tester,
        session: FakeAppSession()
          ..signIn(AppRole.contractor, KycRoutes.statusPath),
      );

      splash.answer(const Success(SplashDestination.home));
      await waitForSplash(tester);
      await tester.pumpAndSettle();
      expect(currentPath(router), KycRoutes.statusPath);
      expect(find.byType(StatusPage), findsOneWidget);
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets(
    'a signed-in verified contractor is redirected directly to contractor navigation without passing through status page',
    (tester) async {
      final router = await pumpAppRouter(
        tester,
        session: FakeAppSession()
          ..signIn(
            AppRole.contractor,
            ContractorNavigationRoutes.navigationPath,
          ),
      );

      splash.answer(const Success(SplashDestination.home));
      await waitForSplash(tester);
      await tester.pumpAndSettle();
      expect(currentPath(router), ContractorNavigationRoutes.navigationPath);
      expect(find.byType(ContractorNavigationPage), findsOneWidget);
      expect(find.byType(StatusPage), findsNothing);
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets('stays on screen for its minimum duration', (tester) async {
    final router = await pumpAppRouter(tester);

    splash.answer(const Success(SplashDestination.login));
    await tester.pump(
      SplashBloc.defaultMinimumDuration - const Duration(milliseconds: 500),
    );
    expect(currentPath(router), SplashRoutes.splashPath);
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(currentPath(router), AuthRoutes.loginPath);
  });
}
