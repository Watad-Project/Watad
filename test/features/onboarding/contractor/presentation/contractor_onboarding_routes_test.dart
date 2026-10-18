import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_onboarding_routes.dart';
import 'package:watad/features/onboarding/contractor/domain/repositories/contractor_onboarding_repository.dart';
import 'package:watad/features/onboarding/contractor/domain/usecases/contractor_save_specialty_use_case.dart';
import 'package:watad/features/onboarding/contractor/presentation/bloc/contractor_specialty_bloc.dart';
import 'package:watad/features/onboarding/contractor/presentation/pages/contractor_specialty_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../../../helpers/pump_router.dart';

class FakeContractorOnboardingRepository
    implements ContractorOnboardingRepository {
  const FakeContractorOnboardingRepository();

  @override
  Future<Result<void>> saveSpecialty(String specialty) async =>
      const Success(null);
}

class FakeSplashRepository implements SplashRepository {
  const FakeSplashRepository(this.result);

  final Result<SplashDestination> result;

  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      result;
}

void main() {
  testWidgets('specialty route opens ContractorSpecialtyPage at its path', (
    tester,
  ) async {
    getIt.registerFactory(
      () => SplashBloc(
        const GetInitialDestinationUseCase(
          FakeSplashRepository(Success(SplashDestination.login)),
        ),
      ),
    );
    getIt.registerFactory<ContractorSpecialtyBloc>(
      () => ContractorSpecialtyBloc(
        const ContractorSaveSpecialtyUseCase(
          FakeContractorOnboardingRepository(),
        ),
      ),
    );
    addTearDown(getIt.reset);

    final router = await pumpAppRouter(tester);

    router.goNamed(ContractorOnboardingRoutes.specialtyName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ContractorOnboardingRoutes.specialtyPath);
    expect(find.byType(ContractorSpecialtyPage), findsOneWidget);
  });
}
