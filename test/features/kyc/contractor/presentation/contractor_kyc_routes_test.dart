import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_upload_license_use_case.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';
import 'package:watad/features/kyc/contractor/presentation/pages/contractor_license_page.dart';
import 'package:watad/features/kyc/contractor/presentation/pages/contractor_status_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../../../helpers/pump_router.dart';

class FakeContractorKycRepository implements ContractorKycRepository {
  @override
  Future<Result<ContractorLicenseSubmission>> uploadLicense({
    required Object bytes,
    required String fileName,
  }) async => throw UnimplementedError();
}

class FakeSplashRepository implements SplashRepository {
  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      const Success(SplashDestination.login);
}

void main() {
  setUp(() {
    getIt.registerFactory(
      () => SplashBloc(GetInitialDestinationUseCase(FakeSplashRepository())),
    );
    getIt.registerFactory(
      () => ContractorLicenseBloc(
        ContractorUploadLicenseUseCase(FakeContractorKycRepository()),
      ),
    );
  });

  tearDown(getIt.reset);

  testWidgets(
    'contractor-license route opens ContractorLicensePage at its path',
    (tester) async {
      final router = await pumpAppRouter(tester);

      router.goNamed(ContractorKycRoutes.licenseName);
      await tester.pumpAndSettle();

      expect(currentPath(router), ContractorKycRoutes.licensePath);
      expect(find.byType(ContractorLicensePage), findsOneWidget);
    },
  );

  testWidgets(
    'contractor-status route opens ContractorStatusPage at its path',
    (tester) async {
      final router = await pumpAppRouter(tester);

      router.goNamed(ContractorKycRoutes.statusName);
      await tester.pumpAndSettle();

      expect(currentPath(router), ContractorKycRoutes.statusPath);
      expect(find.byType(ContractorStatusPage), findsOneWidget);
    },
  );
}
