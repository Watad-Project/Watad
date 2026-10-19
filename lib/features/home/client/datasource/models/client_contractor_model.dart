import 'package:watad/features/home/client/domain/entities/client_contractor.dart';

class ClientContractorModel extends ClientContractor {
  const ClientContractorModel({
    required super.id,
    required super.companyName,
    required super.ratingCount,
    super.completedProjectCount,
    super.isInMyCity,
    super.city,
    super.ratingAvg,
    super.avatarUrl,
  });

  /// Maps the `v_contractors` columns selected in
  /// ClientHomeRemoteDataSourceImpl, plus `avatar_url` built from
  /// `avatar_path`.
  factory ClientContractorModel.fromJson(Map<String, dynamic> json) {
    final city = (json['city'] as String?)?.trim();
    return ClientContractorModel(
      id: json['id'] as String,
      companyName: (json['company_name'] as String?)?.trim() ?? '',
      city: city == null || city.isEmpty ? null : city,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
      completedProjectCount: json['completed_project_count'] as int? ?? 0,
      isInMyCity: json['is_in_my_city'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
