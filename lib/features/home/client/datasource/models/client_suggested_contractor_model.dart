import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';

class ClientSuggestedContractorModel extends ClientSuggestedContractor {
  const ClientSuggestedContractorModel({
    required super.id,
    required super.companyName,
    super.avatarPath,
    super.specializedField,
    super.ratingLabel = '—',
    super.projectsLabel = '—',
    super.isVerified = true,
  });

  factory ClientSuggestedContractorModel.fromJson(Map<String, dynamic> json) {
    return ClientSuggestedContractorModel(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      avatarPath: json['avatar_path'] as String?,
      specializedField: json['specialized_field'] as String?,
    );
  }
}
