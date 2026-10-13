import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';

class ClientHomeProfileModel extends ClientHomeProfile {
  const ClientHomeProfileModel({
    required super.id,
    required super.fullName,
    required super.isPhoneVerified,
    super.avatarPath,
  });

  factory ClientHomeProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientHomeProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      avatarPath: json['avatar_path'] as String?,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
    );
  }
}
