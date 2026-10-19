import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_work_overview_use_case.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';

void main() {
  group('ContractorGetWorkOverviewUseCase', () {
    test('filters out projects where isMine is true', () async {
      final openProject = ContractorOpenProject(
        id: 'proj-1',
        title: 'ترميم مجلس',
        description: 'أعمال جبس ودهان.',
        city: 'الرياض',
        createdAt: DateTime.utc(2026, 10, 18),
        ownerName: 'أحمد المالكي',
        offerCount: 3,
      );
      final ownProject = ContractorOpenProject(
        id: 'proj-2',
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
              openProjects: [openProject, ownProject],
              contractsCount: 4,
            ),
          ),
        ),
      );

      final result = await useCase(const NoParams());

      expect(result, isA<Success<ContractorWorkOverview>>());
      final overview = (result as Success<ContractorWorkOverview>).data;
      expect(overview.openProjects, [openProject]);
      expect(overview.contractsCount, 4);
    });

    test('propagates repository failure', () async {
      const useCase = ContractorGetWorkOverviewUseCase(
        FakeContractorWorkRepository(result: Failed(NetworkFailure())),
      );

      final result = await useCase(const NoParams());

      expect(result, isA<Failed<ContractorWorkOverview>>());
      expect(
        (result as Failed<ContractorWorkOverview>).failure,
        isA<NetworkFailure>(),
      );
    });
  });
}
