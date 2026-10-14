import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';

class ClientSuggestedContractorModel extends ClientSuggestedContractor {
  const ClientSuggestedContractorModel({
    required super.id,
    required super.companyName,
    required super.rating,
    required super.completedProjectsCount,
    required super.isVerified,
    super.avatarPath,
    super.specializedField,
  });

  factory ClientSuggestedContractorModel.fromJson(Map<String, dynamic> json) {
    return ClientSuggestedContractorModel(
      id: json['id']?.toString() ?? '',
      companyName: (json['company_name'] as String?)?.trim() ?? '',
      avatarPath: json['avatar_path'] as String?,
      specializedField: json['specialized_field'] as String?,
      rating: ((json['rating'] ?? json['rating_average'] ?? 0.0) as num)
          .toDouble(),
      completedProjectsCount:
          ((json['completed_projects_count'] ??
                      json['project_count'] ??
                      json['projects_count'] ??
                      0)
                  as num)
              .toInt(),
      isVerified:
          json['is_verified'] == true ||
          json['verification_status'] == 'verified',
    );
  }
}
