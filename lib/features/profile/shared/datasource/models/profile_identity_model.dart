import 'package:watad/features/profile/shared/domain/entities/profile_identity.dart';

class ProfileIdentityModel extends ProfileIdentity {
  const ProfileIdentityModel({required super.nationalId, required super.phone});

  /// Maps the `v_my_identity` columns selected in
  /// ProfileRemoteDataSourceImpl.
  factory ProfileIdentityModel.fromJson(Map<String, dynamic> json) =>
      ProfileIdentityModel(
        nationalId: json['national_id'] as String,
        phone: json['phone'] as String,
      );
}
