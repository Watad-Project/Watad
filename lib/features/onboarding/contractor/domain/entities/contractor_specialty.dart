class ContractorSpecialty {
  const ContractorSpecialty({required this.specializedField});

  final String specializedField;

  static const List<String> availableKeys = [
    'onboarding.specialty_general_contracting',
    'onboarding.specialty_finishes',
    'onboarding.specialty_electrical_plumbing',
    'onboarding.specialty_renovation',
    'onboarding.specialty_insulation',
  ];
}
