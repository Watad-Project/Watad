import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_project_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/inputs/app_segmented_tabs.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_work_overview_use_case.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_work_bloc.dart';
import 'package:watad/features/work/contractor/presentation/pages/contractor_bid_page.dart';
import 'package:watad/features/work/contractor/presentation/pages/contractor_work_page.dart';
import 'package:watad/features/work/contractor/presentation/widgets/contractor_open_project_card.dart';
import 'package:watad/features/work/contractor/presentation/widgets/contractor_work_filter_sheet.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';
import '../../../../../helpers/fake_splash_repository.dart';
import '../../../../../helpers/pump_component.dart';
import '../../../../../helpers/pump_router.dart';

class _AsyncWorkRepository extends FakeContractorWorkRepository {
  _AsyncWorkRepository(this._completer);

  final Completer<Result<ContractorWorkOverview>> _completer;

  @override
  Future<Result<ContractorWorkOverview>> getWorkOverview({
    ContractorWorkFilter filter = const ContractorWorkFilter(),
  }) => _completer.future;
}

class _MutableWorkRepository extends FakeContractorWorkRepository {
  _MutableWorkRepository(this.currentResult, {super.bidDetailsResult});

  Result<ContractorWorkOverview> currentResult;

  @override
  Future<Result<ContractorWorkOverview>> getWorkOverview({
    ContractorWorkFilter filter = const ContractorWorkFilter(),
  }) async => currentResult;
}

void main() {
  final projectWithoutOffer = ContractorOpenProject(
    id: 'proj-1',
    title: 'تأسيس فيلا سكنية دورين',
    description: 'أعمال عظم بالمواد وفق المخططات الهندسية.',
    budget: const Money.halalas(45000000),
    city: 'الرياض',
    district: 'حي الياسمين',
    createdAt: DateTime.utc(2026, 10, 18),
    ownerName: 'سلطان القحطاني',
    offerCount: 4,
  );

  final projectWithPendingOffer = ContractorOpenProject(
    id: 'proj-2',
    title: 'إصلاح تسريبات خزان أرضي',
    description: 'عزل ومعالجة التشققات الداخلية.',
    budget: const Money.halalas(850000),
    city: 'المدينة المنورة',
    createdAt: DateTime.utc(2026, 10, 17),
    ownerName: 'ماجد الحربي',
    offerCount: 1,
    myOfferId: 'offer-99',
    myOfferAmount: const Money.halalas(780000),
    myOfferStatus: OfferStatus.pending,
  );

  final contractWaitingClient = ContractorContractProject(
    id: 'contract-1',
    title: 'تشطيب فيلا سكنية بحي الخالدية',
    status: ProjectStatus.inProgress,
    ownerName: 'عبدالله الحربي',
    agreedAmount: const Money.halalas(48000000),
    totalPaid: const Money.halalas(21600000),
    city: 'المدينة المنورة',
    createdAt: DateTime.utc(2026, 10, 10),
    approvedTasksCount: 3,
    totalTasksCount: 5,
    hasTaskWaitingForClient: true,
  );

  final contractInProgress = ContractorContractProject(
    id: 'contract-2',
    title: 'تأسيس كهرباء وسباكة دور أرضي',
    status: ProjectStatus.inProgress,
    ownerName: 'فيصل العتيبي',
    agreedAmount: const Money.halalas(12000000),
    totalPaid: const Money.halalas(3000000),
    city: 'الرياض',
    createdAt: DateTime.utc(2026, 10, 12),
    approvedTasksCount: 1,
    totalTasksCount: 4,
    hasTaskWaitingForClient: false,
  );

  final contractCompleted = ContractorContractProject(
    id: 'contract-3',
    title: 'ترميم ملحق خارجي كامل',
    status: ProjectStatus.completed,
    ownerName: 'سعد الدوسري',
    agreedAmount: const Money.halalas(9500000),
    totalPaid: const Money.halalas(9500000),
    city: 'جدة',
    createdAt: DateTime.utc(2026, 8, 1),
    approvedTasksCount: 4,
    totalTasksCount: 4,
    hasTaskWaitingForClient: false,
  );

  final sampleOverview = ContractorWorkOverview(
    openProjects: [projectWithoutOffer, projectWithPendingOffer],
    contracts: [contractWaitingClient, contractInProgress, contractCompleted],
  );

  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
  });

  tearDown(getIt.reset);

  testWidgets('displays loading indicator while fetching overview', (
    tester,
  ) async {
    final completer = Completer<Result<ContractorWorkOverview>>();
    getIt.registerFactory(
      () => ContractorWorkBloc(
        ContractorGetWorkOverviewUseCase(_AsyncWorkRepository(completer)),
      ),
    );

    final router = await pumpAppRouter(tester);
    router.goNamed(ContractorWorkRoutes.workName);
    await tester.pump();

    expect(find.byType(AppLoadingIndicator), findsOneWidget);

    completer.complete(Success(sampleOverview));
    await tester.pumpAndSettle();

    expect(find.byType(AppLoadingIndicator), findsNothing);
    expect(find.byType(ContractorWorkPage), findsOneWidget);
  });

  testWidgets('displays error view on failure and retries when tapped', (
    tester,
  ) async {
    final repository = _MutableWorkRepository(const Failed(NetworkFailure()));
    getIt.registerFactory(
      () => ContractorWorkBloc(ContractorGetWorkOverviewUseCase(repository)),
    );

    final router = await pumpAppRouter(tester);
    router.goNamed(ContractorWorkRoutes.workName);
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    repository.currentResult = Success(sampleOverview);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorView), findsNothing);
    expect(find.text('تأسيس فيلا سكنية دورين'), findsOneWidget);
  });

  testWidgets(
    'displays segmented tabs, search & filter controls, open project cards, and My Contracts with AppFilterChips and AppProjectCard',
    (tester) async {
      final repository = _MutableWorkRepository(Success(sampleOverview));
      getIt.registerFactory(
        () => ContractorWorkBloc(ContractorGetWorkOverviewUseCase(repository)),
      );

      final router = await pumpAppRouter(tester);
      router.goNamed(ContractorWorkRoutes.workName);
      await tester.pumpAndSettle();

      // Header and segmented tabs
      expect(find.text('أعمال'), findsOneWidget);
      expect(find.byType(AppSegmentedTabs), findsOneWidget);
      expect(find.text('فرص جديدة 2'), findsOneWidget);
      expect(find.text('عقودي 3'), findsOneWidget);

      // Quick project type filter chips
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('تأسيس'), findsOneWidget);
      expect(find.text('ترميم'), findsOneWidget);
      expect(find.text('إصلاحات'), findsOneWidget);

      // Hint under the switch
      expect(
        find.text(
          'التأسيس والترميم تظهر بعد اعتماد الصك. الإصلاحات تظهر مباشرة.',
        ),
        findsOneWidget,
      );

      // 2-column GridView and Project 1 (no offer submitted yet)
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ContractorOpenProjectCard), findsNWidgets(2));
      expect(find.byIcon(Icons.home_work_rounded), findsNWidgets(2));
      expect(find.text('تأسيس فيلا سكنية دورين'), findsOneWidget);
      expect(find.text('الرياض · حي الياسمين'), findsOneWidget);
      expect(find.text('الميزانية: 450000.0 ر.س'), findsOneWidget);
      expect(find.text('4 عروض'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'تقديم عرض'), findsOneWidget);

      // Project 2 (already submitted pending offer)
      expect(find.text('إصلاح تسريبات خزان أرضي'), findsOneWidget);
      expect(find.text('المدينة المنورة'), findsOneWidget);
      expect(find.text('الميزانية: 8500.0 ر.س'), findsOneWidget);
      expect(find.text('عرض واحد'), findsOneWidget);
      expect(find.text('عرضك 7800.0 ر.س'), findsOneWidget);
      expect(find.byType(AppStatusBadge), findsOneWidget);
      expect(find.text('قيد الانتظار'), findsOneWidget);

      // Quick filter by "إصلاحات"
      await tester.tap(find.text('إصلاحات'));
      await tester.pumpAndSettle();
      expect(find.byType(ContractorOpenProjectCard), findsOneWidget);
      expect(find.text('إصلاح تسريبات خزان أرضي'), findsOneWidget);

      // Reset quick filter to "الكل"
      await tester.tap(find.text('الكل'));
      await tester.pumpAndSettle();
      expect(find.byType(ContractorOpenProjectCard), findsNWidgets(2));

      // Open the filter bottom sheet via the tune icon button
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.byType(ContractorWorkFilterSheet), findsOneWidget);
      expect(find.text('تصفية وترتيب الفرص'), findsOneWidget);
      expect(find.text('نوع العمل'), findsNothing);
      expect(find.text('الموقع'), findsOneWidget);
      expect(find.text('الميزانية: الحد الأدنى (ر.س)'), findsOneWidget);
      expect(find.text('المسافة والترتيب'), findsOneWidget);
      expect(
        find.text('المنافسة: مشاريع بدون عروض فقط (0 عروض)'),
        findsOneWidget,
      );

      // Close filter sheet via Apply
      await tester.tap(find.text('تطبيق الفلترة'));
      await tester.pumpAndSettle();

      // Switch to "عقودي" tab
      await tester.tap(find.text('عقودي 3'));
      await tester.pumpAndSettle();

      // Filter chips: جارية 2 and مكتملة 1
      expect(find.byType(AppFilterChips), findsOneWidget);
      expect(find.text('جارية 2'), findsOneWidget);
      expect(find.text('مكتملة 1'), findsOneWidget);

      // In-progress contract cards rendered via AppProjectCard
      expect(find.byType(AppProjectCard), findsNWidgets(2));
      expect(find.text('تشطيب فيلا سكنية بحي الخالدية'), findsOneWidget);
      expect(find.text('العميل: عبدالله الحربي'), findsOneWidget);
      expect(find.text('بانتظار اعتماد العميل'), findsOneWidget);
      expect(find.text('3 من 5 مهام'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('استلمت 216000.0 ر.س'), findsOneWidget);
      expect(find.text('480000.0 ر.س'), findsOneWidget);

      expect(find.text('تأسيس كهرباء وسباكة دور أرضي'), findsOneWidget);
      expect(find.text('العميل: فيصل العتيبي'), findsOneWidget);
      expect(find.text('قيد التنفيذ'), findsOneWidget);
      expect(find.text('1 من 4 مهام'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);

      // Filter by "مكتملة 1"
      await tester.tap(find.text('مكتملة 1'));
      await tester.pumpAndSettle();

      expect(find.byType(AppProjectCard), findsOneWidget);
      expect(find.text('ترميم ملحق خارجي كامل'), findsOneWidget);
      expect(find.text('العميل: سعد الدوسري'), findsOneWidget);
      expect(find.text('مكتمل'), findsOneWidget);
      expect(find.text('4 من 4 مهام'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('استلمت 95000.0 ر.س'), findsOneWidget);
      expect(find.text('95000.0 ر.س'), findsOneWidget);
    },
  );

  testWidgets(
    'shows empty contracts state with action to switch back to New Opportunities',
    (tester) async {
      final emptyContractsOverview = ContractorWorkOverview(
        openProjects: [projectWithoutOffer],
      );
      registerFakeContractorWorkTab(
        FakeContractorWorkRepository(result: Success(emptyContractsOverview)),
      );

      final router = await pumpAppRouter(tester);
      router.goNamed(ContractorWorkRoutes.workName);
      await tester.pumpAndSettle();

      await tester.tap(find.text('عقودي 0'));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyView), findsOneWidget);
      expect(find.text('لا توجد عقود حالياً'), findsOneWidget);
      expect(find.text('تصفّح الفرص الجديدة'), findsOneWidget);

      await tester.tap(find.text('تصفّح الفرص الجديدة'));
      await tester.pumpAndSettle();

      expect(find.text('تأسيس فيلا سكنية دورين'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a project card in New Opportunities routes to ContractorBidPage',
    (tester) async {
      registerFakeContractorWorkTab(
        _MutableWorkRepository(
          Success(sampleOverview),
          bidDetailsResult: Success(
            ContractorBidDetails(
              project: projectWithoutOffer,
              verificationStatus: VerificationStatus.verified,
            ),
          ),
        ),
      );

      final router = await pumpAppRouter(tester);
      router.goNamed(ContractorWorkRoutes.workName);
      await tester.pumpAndSettle();

      await tester.tap(find.text('تأسيس فيلا سكنية دورين'));
      await tester.pumpAndSettle();

      expect(find.byType(ContractorBidPage), findsOneWidget);
    },
  );

  testWidgets('invokes onSubmitOffer and onPendingOfferTap callbacks', (
    tester,
  ) async {
    ContractorOpenProject? submittedProject;
    ContractorOpenProject? tappedPendingProject;

    await pumpComponent(
      tester,
      Column(
        children: [
          ContractorOpenProjectCard(
            project: projectWithoutOffer,
            onSubmitOfferTap: () => submittedProject = projectWithoutOffer,
          ),
          ContractorOpenProjectCard(
            project: projectWithPendingOffer,
            onPendingOfferTap: () =>
                tappedPendingProject = projectWithPendingOffer,
          ),
        ],
      ),
    );

    await tester.tap(find.widgetWithText(AppButton, 'تقديم عرض'));
    await tester.pump();
    expect(submittedProject?.id, 'proj-1');

    await tester.tap(find.text('عرضك 7800.0 ر.س'));
    await tester.pump();
    expect(tappedPendingProject?.id, 'proj-2');
  });
}
