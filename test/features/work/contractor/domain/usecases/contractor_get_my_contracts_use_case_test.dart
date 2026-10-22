import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_contract_project.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_my_contracts_use_case.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';

void main() {
  group('ContractorGetMyContractsUseCase', () {
    test('returns Success with contractor contracts from repository', () async {
      final contract = ContractorContractProject(
        id: 'contract-1',
        title: 'بناء فيلا سكنية',
        status: ProjectStatus.inProgress,
        ownerName: 'عبدالله الحربي',
        agreedAmount: const Money.halalas(48000000),
        totalPaid: const Money.halalas(21600000),
        city: 'الرياض',
        createdAt: DateTime.utc(2026, 10, 10),
      );
      final useCase = ContractorGetMyContractsUseCase(
        FakeContractorWorkRepository(contractsResult: Success([contract])),
      );

      final result = await useCase(const NoParams());

      expect(result, isA<Success<List<ContractorContractProject>>>());
      final data = (result as Success<List<ContractorContractProject>>).data;
      expect(data.single.id, 'contract-1');
    });

    test('returns Failed when repository fails', () async {
      const useCase = ContractorGetMyContractsUseCase(
        FakeContractorWorkRepository(contractsResult: Failed(NetworkFailure())),
      );

      final result = await useCase(const NoParams());

      expect(result, isA<Failed<List<ContractorContractProject>>>());
    });
  });
}
