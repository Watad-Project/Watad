import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';
import 'package:watad/features/kyc/shared/domain/usecases/get_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/sign_out_kyc_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/watch_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/presentation/bloc/kyc_status_bloc.dart';
import 'package:watad/features/kyc/shared/presentation/pages/status_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

class FakeKycRepository implements KycRepository {
  int signOutCalls = 0;

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

  @override
  Future<Result<void>> signOut() async {
    signOutCalls++;
    return const Success(null);
  }
}

class FakeSplashRepository implements SplashRepository {
  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      const Success(SplashDestination.login);
}

void main() {
  late FakeKycRepository repository;

  setUp(() {
    repository = FakeKycRepository();
    registerFakeAuthBloc(FakeAuthRepository());
    getIt.registerFactory(
      () => SplashBloc(GetInitialDestinationUseCase(FakeSplashRepository())),
    );
    getIt.registerFactory(
      () => KycStatusBloc(
        GetKycDocumentUseCase(repository),
        WatchKycDocumentUseCase(repository),
        SignOutKycUseCase(repository),
      ),
    );
  });

  tearDown(getIt.reset);

  testWidgets(
    'status route opens StatusPage at its path without back button and with sign out',
    (tester) async {
      final router = await pumpAppRouter(tester);

      router.goNamed(KycRoutes.statusName);
      await tester.pumpAndSettle();

      expect(currentPath(router), KycRoutes.statusPath);
      expect(find.byType(StatusPage), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.logout), findsOneWidget);

      final popScope = tester.widget<PopScope<dynamic>>(
        find.byType(PopScope<dynamic>),
      );
      expect(popScope.canPop, isFalse);
    },
  );

  testWidgets('tapping sign out on StatusPage signs out and goes to login', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      initialLocation: KycRoutes.statusPath,
    );

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(currentPath(router), AuthRoutes.loginPath);
    expect(router.canPop(), isFalse);
  });

  testWidgets('StatusPage fits large and bold text', (tester) async {
    await pumpAppRouter(
      tester,
      initialLocation: KycRoutes.statusPath,
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(StatusPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
