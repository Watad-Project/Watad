import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_work_overview_use_case.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';

void main() {
  final constructionProject = ContractorOpenProject(
    id: 'proj-1',
    title: 'تأسيس فيلا سكنية دورين',
    description: 'بناء عظم بالمواد.',
    budget: const Money.halalas(45000000),
    city: 'الرياض',
    district: 'حي الياسمين',
    createdAt: DateTime.utc(2026, 10, 18),
    ownerName: 'أحمد المالكي',
    offerCount: 3,
  );

  final renovationProject = ContractorOpenProject(
    id: 'proj-2',
    title: 'ترميم مجلس خارجي',
    description: 'دهان وجبس وبلاط.',
    budget: const Money.halalas(6500000),
    city: 'المدينة المنورة',
    district: 'حي العوالي',
    createdAt: DateTime.utc(2026, 10, 19),
    ownerName: 'فهد الشمري',
    offerCount: 0,
  );

  final repairsProject = ContractorOpenProject(
    id: 'proj-3',
    title: 'إصلاح تسريب خزان أرضي',
    description: 'صيانة وعزل.',
    budget: const Money.halalas(850000),
    city: 'الرياض',
    district: 'حي النرجس',
    createdAt: DateTime.utc(2026, 10, 17),
    ownerName: 'خالد السالم',
    offerCount: 0,
  );

  group('ContractorGetWorkOverviewUseCase', () {
    test('filters out projects where isMine is true', () async {
      final ownProject = ContractorOpenProject(
        id: 'proj-own',
        title: 'مشروعي الخاص',
        description: 'مشروع يملكه المقاول نفسه.',
        city: 'الرياض',
        createdAt: DateTime.utc(2026, 10, 19),
        ownerName: 'أنا',
        offerCount: 0,
        isMine: true,
      );
      final useCase = ContractorGetWorkOverviewUseCase(
        FakeContractorWorkRepository(
          result: Success(
            ContractorWorkOverview(
              openProjects: [constructionProject, ownProject],
              contractsCount: 4,
            ),
          ),
        ),
      );

      final result = await useCase();

      expect(result, isA<Success<ContractorWorkOverview>>());
      final overview = (result as Success<ContractorWorkOverview>).data;
      expect(overview.openProjects, [constructionProject]);
      expect(overview.contractsCount, 4);
    });

    test('applies searchQuery, projectType, city/district, minBudget, sortBy, and zeroOffersOnly', () async {
      final useCase = ContractorGetWorkOverviewUseCase(
        FakeContractorWorkRepository(
          result: Success(
            ContractorWorkOverview(
              openProjects: [
                constructionProject,
                renovationProject,
                repairsProject,
              ],
            ),
          ),
        ),
      );

      // Filter by projectType = renovation
      final renovationResult = await useCase(
        const ContractorWorkFilter(projectType: ContractorWorkType.renovation),
      );
      expect(
        (renovationResult as Success<ContractorWorkOverview>).data.openProjects
            .map((p) => p.id),
        ['proj-2'],
      );

      // Filter by city, zeroOffersOnly, and sort by highestBudget
      final zeroOffersResult = await useCase(
        const ContractorWorkFilter(
          zeroOffersOnly: true,
          sortBy: ContractorWorkSortBy.highestBudget,
        ),
      );
      expect(
        (zeroOffersResult as Success<ContractorWorkOverview>).data.openProjects
            .map((p) => p.id),
        ['proj-2', 'proj-3'],
      );

      // Filter by minBudget = 100,000 SAR
      final minBudgetResult = await useCase(
        const ContractorWorkFilter(minBudget: Money.halalas(10000000)),
      );
      expect(
        (minBudgetResult as Success<ContractorWorkOverview>).data.openProjects
            .map((p) => p.id),
        ['proj-1'],
      );
    });

    test('propagates repository failure', () async {
      const useCase = ContractorGetWorkOverviewUseCase(
        FakeContractorWorkRepository(result: Failed(NetworkFailure())),
      );

      final result = await useCase();

      expect(result, isA<Failed<ContractorWorkOverview>>());
      expect(
        (result as Failed<ContractorWorkOverview>).failure,
        isA<NetworkFailure>(),
      );
    });
  });
}
