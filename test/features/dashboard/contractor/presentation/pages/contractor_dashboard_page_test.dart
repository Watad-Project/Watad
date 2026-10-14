import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_project_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_dashboard_routes.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_earnings.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_offer.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_project.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';
import 'package:watad/features/dashboard/contractor/domain/usecases/contractor_get_dashboard_data_use_case.dart';
import 'package:watad/features/dashboard/contractor/presentation/bloc/contractor_dashboard_bloc.dart';
import 'package:watad/features/dashboard/contractor/presentation/pages/contractor_dashboard_page.dart';

import '../../../../../helpers/fake_splash_repository.dart';
import '../../../../../helpers/pump_router.dart';

class FakeAsyncDashboardRepository implements ContractorDashboardRepository {
  FakeAsyncDashboardRepository(this._completer);

  final Completer<Result<ContractorDashboardData>> _completer;

  @override
  Future<Result<ContractorDashboardData>> getDashboardData() =>
      _completer.future;
}

class FakeSyncDashboardRepository implements ContractorDashboardRepository {
  FakeSyncDashboardRepository(this.result);

  Result<ContractorDashboardData> result;

  @override
  Future<Result<ContractorDashboardData>> getDashboardData() async => result;
}

void main() {
  final testData = ContractorDashboardData(
    profile: const ContractorDashboardProfile(
      companyName: 'مؤسسة البناء المتين',
      verificationStatus: VerificationStatus.pending,
    ),
    earnings: const ContractorDashboardEarnings(
      thisMonthEarnings: Money.halalas(1250000),
      pendingTransfers: Money.halalas(320000),
    ),
    opportunitiesCount: 6,
    activeProjects: [
      ContractorDashboardProject(
        id: 'proj-1',
        title: 'ترميم فيلا سكنية',
        clientName: 'أحمد العتيبي',
        status: ProjectStatus.inProgress,
        approvedTasksCount: 3,
        totalTasksCount: 5,
        createdAt: DateTime.utc(2026, 10, 10),
        budget: const Money.halalas(5000000),
        city: 'المدينة المنورة',
      ),
    ],
    myOffers: [
      ContractorDashboardOffer(
        id: 'offer-1',
        projectId: 'proj-1',
        projectTitle: 'ترميم فيلا سكنية',
        amount: const Money.halalas(320000),
        status: OfferStatus.pending,
        createdAt: DateTime.utc(2026, 10, 12),
      ),
    ],
  );

  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
  });

  tearDown(getIt.reset);

  testWidgets('displays loading indicator while waiting for data', (
    tester,
  ) async {
    final completer = Completer<Result<ContractorDashboardData>>();
    final repository = FakeAsyncDashboardRepository(completer);

    getIt.registerFactory(
      () => ContractorDashboardBloc(
        ContractorGetDashboardDataUseCase(repository),
      ),
    );

    final router = await pumpAppRouter(tester);
    router.goNamed(ContractorDashboardRoutes.dashboardName);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(Success(testData));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ContractorDashboardPage), findsOneWidget);
  });

  testWidgets('displays error message and retries on failure', (tester) async {
    final repository = FakeSyncDashboardRepository(
      const Failed(NetworkFailure()),
    );

    getIt.registerFactory(
      () => ContractorDashboardBloc(
        ContractorGetDashboardDataUseCase(repository),
      ),
    );

    final router = await pumpAppRouter(tester);
    router.goNamed(ContractorDashboardRoutes.dashboardName);
    await tester.pumpAndSettle();

    expect(find.text('إعادة المحاولة'), findsOneWidget);

    repository.result = Success(testData);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('مؤسسة البناء المتين'), findsOneWidget);
  });

  testWidgets('displays complete dashboard content on success', (tester) async {
    final repository = FakeSyncDashboardRepository(Success(testData));

    getIt.registerFactory(
      () => ContractorDashboardBloc(
        ContractorGetDashboardDataUseCase(repository),
      ),
    );

    final router = await pumpAppRouter(tester);
    router.goNamed(ContractorDashboardRoutes.dashboardName);
    await tester.pumpAndSettle();

    // 1. Header
    expect(find.text('مؤسسة البناء المتين'), findsOneWidget);
    expect(find.text('اللوحة'), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget); // Header badge

    // 2. Earnings card
    expect(find.text('أرباح هذا الشهر'), findsOneWidget);
    expect(find.text('12500.0 ر.س'), findsOneWidget);
    expect(find.text('قيد التحويل'), findsOneWidget);
    expect(find.text('3200.0 ر.س'), findsOneWidget);

    // 3. Opportunities banner
    expect(find.textContaining('فرص جديدة قريبة منك'), findsOneWidget);
    expect(find.text('تصفّح'), findsOneWidget);

    // 4. In Progress section
    expect(find.text('قيد التنفيذ'), findsOneWidget);
    expect(find.byType(AppProjectCard), findsOneWidget);
    expect(
      find.text('ترميم فيلا سكنية'),
      findsNWidgets(2),
    ); // in project & offer
    expect(find.text('العميل: أحمد العتيبي'), findsOneWidget);
    expect(find.textContaining('من 5 مهام'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);

    // 5. My Offers section
    expect(find.text('عروضي المقدّمة'), findsOneWidget);
    expect(find.text('عرضك 3200.0 ر.س'), findsOneWidget);
    expect(find.text('قيد الانتظار'), findsOneWidget); // Offer badge
    expect(find.byType(AppStatusBadge), findsNWidgets(3));
  });
}
