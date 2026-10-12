import 'package:watad/features/onboarding/contractor/domain/entities/contractor_specialty.dart';

class ContractorSpecialtyModel extends ContractorSpecialty {
  const ContractorSpecialtyModel({required super.specializedField});

  factory ContractorSpecialtyModel.fromJson(Map<String, dynamic> json) {
    return ContractorSpecialtyModel(
      specializedField: json['specialized_field'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'specialized_field': specializedField};
}
