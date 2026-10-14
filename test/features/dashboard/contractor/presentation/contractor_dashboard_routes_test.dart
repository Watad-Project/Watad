import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_dashboard_routes.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_earnings.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';
import 'package:watad/features/dashboard/contractor/domain/usecases/contractor_get_dashboard_data_use_case.dart';
import 'package:watad/features/dashboard/contractor/presentation/bloc/contractor_dashboard_bloc.dart';
import 'package:watad/features/dashboard/contractor/presentation/pages/contractor_dashboard_page.dart';

import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

class FakeContractorDashboardRepository
    implements ContractorDashboardRepository {
  @override
  Future<Result<ContractorDashboardData>> getDashboardData() async {
    return const Success(
      ContractorDashboardData(
        profile: ContractorDashboardProfile(
          companyName: 'مؤسسة البناء المتين',
          verificationStatus: VerificationStatus.verified,
        ),
        earnings: ContractorDashboardEarnings(
          thisMonthEarnings: Money.halalas(1250000),
          pendingTransfers: Money.halalas(320000),
        ),
        opportunitiesCount: 6,
        activeProjects: [],
        myOffers: [],
      ),
    );
  }
}

void main() {
  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
    getIt.registerFactory(
      () => ContractorDashboardBloc(
        ContractorGetDashboardDataUseCase(FakeContractorDashboardRepository()),
      ),
    );
  });

  tearDown(getIt.reset);

  testWidgets('every contractor dashboard route opens its page at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(ContractorDashboardRoutes.dashboardName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ContractorDashboardRoutes.dashboardPath);
    expect(find.byType(ContractorDashboardPage), findsOneWidget);
  });

  testWidgets('opens directly at dashboardPath when set as initialLocation', (
    tester,
  ) async {
    final router = await pumpAppRouter(
      tester,
      initialLocation: ContractorDashboardRoutes.dashboardPath,
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), ContractorDashboardRoutes.dashboardPath);
    expect(find.byType(ContractorDashboardPage), findsOneWidget);
  });

  testWidgets('handles route without leading slash', (tester) async {
    final router = await pumpAppRouter(
      tester,
      initialLocation: 'contractor/dashboard',
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), ContractorDashboardRoutes.dashboardPath);
    expect(find.byType(ContractorDashboardPage), findsOneWidget);
  });
}
