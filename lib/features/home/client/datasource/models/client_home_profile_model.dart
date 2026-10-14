import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';

class ClientHomeProfileModel extends ClientHomeProfile {
  const ClientHomeProfileModel({
    required super.fullName,
    required super.isPhoneVerified,
    super.avatarPath,
  });

  factory ClientHomeProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientHomeProfileModel(
      fullName: (json['full_name'] as String?)?.trim() ?? '',
      avatarPath: json['avatar_path'] as String?,
      isPhoneVerified:
          json['is_phone_verified'] == true ||
          json['phone'] != null ||
          json['phone_verified'] == true,
    );
  }
}
