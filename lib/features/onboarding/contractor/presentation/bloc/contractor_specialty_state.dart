part of 'contractor_specialty_bloc.dart';

sealed class ContractorSpecialtyState {
  const ContractorSpecialtyState({this.selectedSpecialty});

  final String? selectedSpecialty;
}

final class ContractorSpecialtyInitial extends ContractorSpecialtyState {
  const ContractorSpecialtyInitial({super.selectedSpecialty});
}

final class ContractorSpecialtySaveInProgress extends ContractorSpecialtyState {
  const ContractorSpecialtySaveInProgress({super.selectedSpecialty});
}

final class ContractorSpecialtySaveSuccess extends ContractorSpecialtyState {
  const ContractorSpecialtySaveSuccess({required String specialty})
    : super(selectedSpecialty: specialty);
}

final class ContractorSpecialtySaveFailure extends ContractorSpecialtyState {
  const ContractorSpecialtySaveFailure({
    required this.failure,
    super.selectedSpecialty,
  });

  final Failure failure;
}
