import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/app_router.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/core/router/routes/contractor_onboarding_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_upload_license_use_case.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';
import 'package:watad/features/kyc/shared/domain/usecases/get_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/watch_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/presentation/bloc/kyc_status_bloc.dart';
import 'package:watad/features/onboarding/contractor/domain/repositories/contractor_onboarding_repository.dart';
import 'package:watad/features/onboarding/contractor/domain/usecases/contractor_save_specialty_use_case.dart';
import 'package:watad/features/onboarding/contractor/presentation/bloc/contractor_specialty_bloc.dart';

import '../../helpers/fake_admin_review_repository.dart';
import '../../helpers/fake_app_session.dart';
import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_splash_repository.dart';
import '../../helpers/pump_router.dart';

/// A session whose role can't be read, e.g. offline.
class _UnreadableRoleSession extends FakeAppSession {
  @override
  Future<AppRole> role() async => throw Exception('offline');
}

class _FakeContractorKycRepository implements ContractorKycRepository {
  @override
  Future<Result<ContractorLicenseSubmission>> uploadLicense({
    required Uint8List bytes,
    required String fileName,
  }) async => throw UnimplementedError();
}

class _FakeContractorOnboardingRepository
    implements ContractorOnboardingRepository {
  const _FakeContractorOnboardingRepository();

  @override
  Future<Result<void>> saveSpecialty(String specialty) async =>
      const Success(null);
}

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

// Each role folder tests its own routes in
// test/features/<feature>/<role>/presentation/ (APP_ARCHITECTURE.md §11).
void main() {
  setUp(() {
    // The splash fake never answers, so the app stays at its start path.
    registerFakeSplashBloc(FakeSplashRepository());
    registerFakeAuthBloc(FakeAuthRepository());
    // The admin's navigation opens on its «التوثيق» tab.
    registerFakeAdminReview(FakeAdminReviewRepository());
    getIt.registerFactory(
      () => ContractorLicenseBloc(
        ContractorUploadLicenseUseCase(_FakeContractorKycRepository()),
      ),
    );
    getIt.registerFactory<ContractorSpecialtyBloc>(
      () => ContractorSpecialtyBloc(
        const ContractorSaveSpecialtyUseCase(
          _FakeContractorOnboardingRepository(),
        ),
      ),
    );
    getIt.registerFactory(
      () => KycStatusBloc(
        GetKycDocumentUseCase(_FakeKycRepository()),
        WatchKycDocumentUseCase(_FakeKycRepository()),
      ),
    );
  });

  tearDown(getIt.reset);

  testWidgets('starts at the start path', (tester) async {
    final router = await pumpAppRouter(tester);

    expect(currentPath(router), appStartPath);
  });

  testWidgets('an unknown address shows the not-found page', (tester) async {
    final router = await pumpAppRouter(tester);

    router.go('/no-such-page');
    await tester.pumpAndSettle();
    expect(find.byType(AppNotFoundView), findsOneWidget);

    await tester.tap(find.text('العودة إلى البداية'));
    await tester.pumpAndSettle();
    expect(currentPath(router), appStartPath);
  });

  testWidgets('a route the guard does not watch opens in the same frame', (
    tester,
  ) async {
    final router = await pumpAppRouter(tester);

    router.go('/no-such-page');
    await tester.pump();
    expect(find.byType(AppNotFoundView), findsOneWidget);
  });

  group('the guard', () {
    const navigationOf = {
      AppRole.client: ClientNavigationRoutes.navigationPath,
      AppRole.contractor: ContractorNavigationRoutes.navigationPath,
      AppRole.admin: AdminNavigationRoutes.navigationPath,
    };

    for (final MapEntry(key: role, value: path) in navigationOf.entries) {
      testWidgets('signing in on the login page opens the ${role.name} '
          'navigation', (tester) async {
        final session = FakeAppSession();
        final router = await pumpAppRouter(
          tester,
          session: session,
          initialLocation: AuthRoutes.loginPath,
        );
        expect(currentPath(router), AuthRoutes.loginPath);

        // What the login page's verified code does to the session.
        session.signIn(role);
        await tester.pumpAndSettle();
        expect(currentPath(router), path);
        expect(router.canPop(), isFalse);
      });
    }

    testWidgets('a signed-in user who opens the login page goes on to their '
        'navigation', (tester) async {
      final router = await pumpAppRouter(
        tester,
        session: FakeAppSession()..signIn(AppRole.contractor),
      );

      router.goNamed(AuthRoutes.loginName);
      await tester.pumpAndSettle();
      expect(currentPath(router), ContractorNavigationRoutes.navigationPath);
    });

    testWidgets('signed out, a navigation sends to the login page', (
      tester,
    ) async {
      final router = await pumpAppRouter(tester);

      router.goNamed(ClientNavigationRoutes.navigationName);
      await tester.pumpAndSettle();
      expect(currentPath(router), AuthRoutes.loginPath);
    });

    testWidgets("a role can't open another role's navigation", (tester) async {
      final router = await pumpAppRouter(
        tester,
        session: FakeAppSession()..signIn(AppRole.client),
      );

      router.goNamed(AdminNavigationRoutes.navigationName);
      await tester.pumpAndSettle();
      expect(currentPath(router), ClientNavigationRoutes.navigationPath);
    });

    testWidgets('signing out on a navigation goes to the login page', (
      tester,
    ) async {
      final session = FakeAppSession()..signIn(AppRole.admin);
      final router = await pumpAppRouter(
        tester,
        session: session,
        initialLocation: AdminNavigationRoutes.navigationPath,
      );
      expect(currentPath(router), AdminNavigationRoutes.navigationPath);

      session.signOut();
      await tester.pumpAndSettle();
      expect(currentPath(router), AuthRoutes.loginPath);
    });

    testWidgets("when the role can't be read, the user stays on the login "
        'page', (tester) async {
      final session = _UnreadableRoleSession();
      final router = await pumpAppRouter(
        tester,
        session: session,
        initialLocation: AuthRoutes.loginPath,
      );

      session.signIn(AppRole.client);
      await tester.pumpAndSettle();
      expect(currentPath(router), AuthRoutes.loginPath);
    });

    testWidgets(
      'a contractor with missing license is redirected to license page',
      (tester) async {
        final session = FakeAppSession()
          ..signIn(AppRole.contractor, ContractorKycRoutes.licensePath);
        final router = await pumpAppRouter(
          tester,
          session: session,
          initialLocation: AuthRoutes.loginPath,
        );

        router.goNamed(AuthRoutes.loginName);
        await tester.pumpAndSettle();
        expect(currentPath(router), ContractorKycRoutes.licensePath);
      },
    );

    testWidgets(
      'a contractor with missing specialty is redirected to specialty page',
      (tester) async {
        final session = FakeAppSession()
          ..signIn(
            AppRole.contractor,
            ContractorOnboardingRoutes.specialtyPath,
          );
        final router = await pumpAppRouter(
          tester,
          session: session,
          initialLocation: AuthRoutes.loginPath,
        );

        router.goNamed(AuthRoutes.loginName);
        await tester.pumpAndSettle();
        expect(currentPath(router), ContractorOnboardingRoutes.specialtyPath);
      },
    );

    testWidgets(
      'a contractor pending KYC verification is redirected to KYC status page',
      (tester) async {
        final session = FakeAppSession()
          ..signIn(AppRole.contractor, KycRoutes.statusPath);
        final router = await pumpAppRouter(
          tester,
          session: session,
          initialLocation: AuthRoutes.loginPath,
        );

        router.goNamed(AuthRoutes.loginName);
        await tester.pumpAndSettle();
        expect(currentPath(router), KycRoutes.statusPath);
      },
    );

    testWidgets(
      'a verified contractor navigating to KYC status page is redirected to contractor navigation',
      (tester) async {
        final session = FakeAppSession()
          ..signIn(
            AppRole.contractor,
            ContractorNavigationRoutes.navigationPath,
          );
        final router = await pumpAppRouter(
          tester,
          session: session,
          initialLocation: KycRoutes.statusPath,
        );

        router.goNamed(KycRoutes.statusName);
        await tester.pumpAndSettle();
        expect(currentPath(router), ContractorNavigationRoutes.navigationPath);
      },
    );

    testWidgets(
      'a pending contractor navigating to contractor navigation is redirected to KYC status page',
      (tester) async {
        final session = FakeAppSession()
          ..signIn(AppRole.contractor, KycRoutes.statusPath);
        final router = await pumpAppRouter(
          tester,
          session: session,
          initialLocation: ContractorNavigationRoutes.navigationPath,
        );

        router.goNamed(ContractorNavigationRoutes.navigationName);
        await tester.pumpAndSettle();
        expect(currentPath(router), KycRoutes.statusPath);
      },
    );
  });
}
