import 'package:watad/features/home/client/domain/entities/client_contractor.dart';

class ClientContractorModel extends ClientContractor {
  const ClientContractorModel({
    required super.id,
    required super.companyName,
    required super.ratingCount,
    super.ratingAvg,
    super.avatarUrl,
  });

  /// Maps the `v_public_profiles` columns selected in
  /// ClientHomeRemoteDataSourceImpl, plus `avatar_url` built from
  /// `avatar_path`.
  factory ClientContractorModel.fromJson(Map<String, dynamic> json) {
    return ClientContractorModel(
      id: json['id'] as String,
      companyName: (json['company_name'] as String?)?.trim() ?? '',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int? ?? 0,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
