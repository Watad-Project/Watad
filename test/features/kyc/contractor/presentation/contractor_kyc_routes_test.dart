import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_sign_out_use_case.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_upload_license_use_case.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';
import 'package:watad/features/kyc/contractor/presentation/pages/contractor_license_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

class FakeContractorKycRepository implements ContractorKycRepository {
  int signOutCalls = 0;

  @override
  Future<Result<ContractorLicenseSubmission>> uploadLicense({
    required Uint8List bytes,
    required String fileName,
  }) async => throw UnimplementedError();

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
  late FakeContractorKycRepository repository;

  setUp(() {
    repository = FakeContractorKycRepository();
    registerFakeAuthBloc(FakeAuthRepository());
    getIt.registerFactory(
      () => SplashBloc(GetInitialDestinationUseCase(FakeSplashRepository())),
    );
    getIt.registerFactory(
      () => ContractorLicenseBloc(
        ContractorUploadLicenseUseCase(repository),
        ContractorSignOutUseCase(repository),
      ),
    );
  });

  tearDown(getIt.reset);

  testWidgets(
    'contractor-license route opens ContractorLicensePage at its path without back button',
    (tester) async {
      final router = await pumpAppRouter(tester);

      router.goNamed(ContractorKycRoutes.licenseName);
      await tester.pumpAndSettle();

      expect(currentPath(router), ContractorKycRoutes.licensePath);
      expect(find.byType(ContractorLicensePage), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.logout), findsOneWidget);

      final popScope = tester.widget<PopScope<dynamic>>(
        find.byType(PopScope<dynamic>),
      );
      expect(popScope.canPop, isFalse);
    },
  );

  testWidgets(
    'system back on contractor-license page does not pop back to previous route',
    (tester) async {
      await pumpAppRouter(tester, initialLocation: AuthRoutes.loginPath);

      final loginContext = tester.element(find.byType(Scaffold).first);
      unawaited(
        GoRouter.of(loginContext).pushNamed(ContractorKycRoutes.licenseName),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContractorLicensePage), findsOneWidget);

      final context = tester.element(find.byType(ContractorLicensePage));
      final popped = await Navigator.maybePop(context);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.byType(ContractorLicensePage), findsOneWidget);
    },
  );

  testWidgets(
    'tapping sign out on contractor-license page signs out and goes to login',
    (tester) async {
      final router = await pumpAppRouter(
        tester,
        initialLocation: ContractorKycRoutes.licensePath,
      );

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(repository.signOutCalls, 1);
      expect(currentPath(router), AuthRoutes.loginPath);
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets('ContractorLicensePage fits large and bold text', (tester) async {
    await pumpAppRouter(
      tester,
      initialLocation: ContractorKycRoutes.licensePath,
      textScale: largeTextScale,
      boldText: true,
    );

    expect(find.byType(ContractorLicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
