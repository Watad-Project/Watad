import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/onboarding/contractor/domain/repositories/contractor_onboarding_repository.dart';
import 'package:watad/features/onboarding/contractor/domain/usecases/contractor_save_specialty_use_case.dart';
import 'package:watad/features/onboarding/contractor/presentation/bloc/contractor_specialty_bloc.dart';

class FakeContractorOnboardingRepository
    implements ContractorOnboardingRepository {
  FakeContractorOnboardingRepository(this.result);

  Result<void> result;
  String? lastSavedSpecialty;

  @override
  Future<Result<void>> saveSpecialty(String specialty) async {
    lastSavedSpecialty = specialty;
    return result;
  }
}

void main() {
  group('ContractorSpecialtyBloc', () {
    test('updates selectedSpecialty on ContractorSpecialtySelected', () {
      final repository = FakeContractorOnboardingRepository(
        const Success(null),
      );
      final useCase = ContractorSaveSpecialtyUseCase(repository);
      final bloc = ContractorSpecialtyBloc(useCase);
      addTearDown(bloc.close);

      expect(
        bloc.stream,
        emits(
          isA<ContractorSpecialtyInitial>().having(
            (s) => s.selectedSpecialty,
            'selectedSpecialty',
            'مقاولات عامة',
          ),
        ),
      );

      bloc.add(const ContractorSpecialtySelected('مقاولات عامة'));
    });

    test('emits SaveInProgress then SaveSuccess on successful save', () {
      final repository = FakeContractorOnboardingRepository(
        const Success(null),
      );
      final useCase = ContractorSaveSpecialtyUseCase(repository);
      final bloc = ContractorSpecialtyBloc(useCase);
      addTearDown(bloc.close);

      expect(
        bloc.stream,
        emitsInOrder([
          isA<ContractorSpecialtySaveInProgress>().having(
            (s) => s.selectedSpecialty,
            'selectedSpecialty',
            'تشطيبات',
          ),
          isA<ContractorSpecialtySaveSuccess>().having(
            (s) => s.selectedSpecialty,
            'selectedSpecialty',
            'تشطيبات',
          ),
        ]),
      );

      bloc.add(const ContractorSpecialtySaved('تشطيبات'));
    });

    test('emits SaveInProgress then SaveFailure on failed save', () {
      final repository = FakeContractorOnboardingRepository(
        const Failed(NetworkFailure()),
      );
      final useCase = ContractorSaveSpecialtyUseCase(repository);
      final bloc = ContractorSpecialtyBloc(useCase);
      addTearDown(bloc.close);

      expect(
        bloc.stream,
        emitsInOrder([
          isA<ContractorSpecialtySaveInProgress>().having(
            (s) => s.selectedSpecialty,
            'selectedSpecialty',
            'عزل',
          ),
          isA<ContractorSpecialtySaveFailure>()
              .having((s) => s.selectedSpecialty, 'selectedSpecialty', 'عزل')
              .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
        ]),
      );

      bloc.add(const ContractorSpecialtySaved('عزل'));
    });
  });
}
