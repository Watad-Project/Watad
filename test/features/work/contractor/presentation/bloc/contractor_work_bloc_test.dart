import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_filter.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_work_overview.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_work_overview_use_case.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_work_bloc.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';

void main() {
  final inProgressContract = ContractorContractProject(
    id: 'contract-1',
    title: 'تشطيب فيلا دورين',
    status: ProjectStatus.inProgress,
    ownerName: 'عبدالله الحربي',
    agreedAmount: const Money.halalas(48000000),
    totalPaid: const Money.halalas(21600000),
    city: 'الرياض',
    createdAt: DateTime.utc(2026, 10, 10),
    approvedTasksCount: 3,
    totalTasksCount: 5,
    hasTaskWaitingForClient: true,
  );

  final completedContract = ContractorContractProject(
    id: 'contract-2',
    title: 'ترميم ملحق خارجي',
    status: ProjectStatus.completed,
    ownerName: 'خالد السبيعي',
    agreedAmount: const Money.halalas(9000000),
    totalPaid: const Money.halalas(9000000),
    city: 'جدة',
    createdAt: DateTime.utc(2026, 8, 1),
    approvedTasksCount: 4,
    totalTasksCount: 4,
  );

  final sampleOverview = ContractorWorkOverview(
    openProjects: [
      ContractorOpenProject(
        id: 'proj-1',
        title: 'بناء ملحق علوي',
        description: 'بناء ملحق مع التشطيب.',
        city: 'الرياض',
        district: 'حي النرجس',
        createdAt: DateTime.utc(2026, 10, 18),
        ownerName: 'عبدالله السالم',
        offerCount: 5,
      ),
      ContractorOpenProject(
        id: 'proj-2',
        title: 'إصلاح تسريب خزان',
        description: 'عزل مائي.',
        city: 'جدة',
        createdAt: DateTime.utc(2026, 10, 19),
        ownerName: 'سالم الحربي',
        offerCount: 0,
      ),
    ],
    contracts: [inProgressContract, completedContract],
  );

  group('ContractorWorkBloc', () {
    test('initial state is ContractorWorkInitial', () {
      final bloc = ContractorWorkBloc(
        const ContractorGetWorkOverviewUseCase(FakeContractorWorkRepository()),
      );
      addTearDown(bloc.close);

      expect(bloc.state, isA<ContractorWorkInitial>());
    });

    test(
      'emits LoadInProgress then LoadSuccess on ContractorWorkStarted',
      () async {
        final bloc = ContractorWorkBloc(
          ContractorGetWorkOverviewUseCase(
            FakeContractorWorkRepository(result: Success(sampleOverview)),
          ),
        );
        addTearDown(bloc.close);

        final states = <ContractorWorkState>[];
        final sub = bloc.stream.listen(states.add);
        addTearDown(sub.cancel);

        bloc.add(const ContractorWorkStarted());
        await Future<void>.delayed(Duration.zero);

        expect(states, hasLength(2));
        expect(states[0], isA<ContractorWorkLoadInProgress>());
        expect(states[1], isA<ContractorWorkLoadSuccess>());
        final success = states[1] as ContractorWorkLoadSuccess;
        expect(success.overview.opportunitiesCount, 2);
        expect(success.overview.contractsCount, 2);
        expect(success.selectedTabIndex, 0);
        expect(success.selectedContractFilterIndex, 0);
        expect(success.filteredContracts.single.id, 'contract-1');
      },
    );

    test(
      'emits LoadInProgress then LoadFailure when repository fails',
      () async {
        final bloc = ContractorWorkBloc(
          const ContractorGetWorkOverviewUseCase(
            FakeContractorWorkRepository(result: Failed(NetworkFailure())),
          ),
        );
        addTearDown(bloc.close);

        final states = <ContractorWorkState>[];
        final sub = bloc.stream.listen(states.add);
        addTearDown(sub.cancel);

        bloc.add(const ContractorWorkStarted());
        await Future<void>.delayed(Duration.zero);

        expect(states, hasLength(2));
        expect(states[0], isA<ContractorWorkLoadInProgress>());
        expect(states[1], isA<ContractorWorkLoadFailure>());
      },
    );

    test('updates selectedTabIndex, selectedContractFilterIndex, searchQuery, and filter', () async {
      final bloc = ContractorWorkBloc(
        ContractorGetWorkOverviewUseCase(
          FakeContractorWorkRepository(result: Success(sampleOverview)),
        ),
      );
      addTearDown(bloc.close);

      bloc
        ..add(const ContractorWorkStarted())
        ..add(const ContractorWorkTabChanged(1))
        ..add(const ContractorWorkContractFilterChanged(1))
        ..add(const ContractorWorkSearchQueryChanged('خزان'))
        ..add(
          const ContractorWorkFilterUpdated(
            ContractorWorkFilter(
              searchQuery: 'خزان',
              projectType: ContractorWorkType.repairs,
              zeroOffersOnly: true,
            ),
          ),
        )
        ..add(const ContractorWorkRefreshed());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ContractorWorkLoadSuccess>());
      final success = bloc.state as ContractorWorkLoadSuccess;
      expect(success.selectedTabIndex, 1);
      expect(success.selectedContractFilterIndex, 1);
      expect(success.filteredContracts.single.id, 'contract-2');
      expect(success.filter.searchQuery, 'خزان');
      expect(success.filter.projectType, ContractorWorkType.repairs);
      expect(success.filter.zeroOffersOnly, isTrue);
      expect(success.overview.openProjects.single.id, 'proj-2');

      bloc.add(const ContractorWorkFilterReset());
      await Future<void>.delayed(Duration.zero);

      final resetState = bloc.state as ContractorWorkLoadSuccess;
      expect(resetState.filter.hasActiveFilters, isFalse);
      expect(resetState.overview.openProjects, hasLength(2));
    });
  });
}
