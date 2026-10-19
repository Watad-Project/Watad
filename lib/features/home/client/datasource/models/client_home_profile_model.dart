import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';

class ClientHomeProfileModel extends ClientHomeProfile {
  const ClientHomeProfileModel({
    required super.fullName,
    required super.isPhoneVerified,
  });

  /// Maps the `v_my_profile` row read in ClientHomeRemoteDataSourceImpl,
  /// plus `is_phone_verified` from Supabase Auth.
  factory ClientHomeProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientHomeProfileModel(
      fullName: (json['full_name'] as String?)?.trim() ?? '',
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
    );
  }
}
