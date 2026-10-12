part of 'contractor_specialty_bloc.dart';

sealed class ContractorSpecialtyEvent {
  const ContractorSpecialtyEvent();
}

final class ContractorSpecialtySelected extends ContractorSpecialtyEvent {
  const ContractorSpecialtySelected(this.specialty);

  final String specialty;
}

final class ContractorSpecialtySaved extends ContractorSpecialtyEvent {
  const ContractorSpecialtySaved(this.specialty);

  final String specialty;
}
