import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';

class MyProfileModel extends MyProfile {
  const MyProfileModel({
    required super.id,
    required super.fullName,
    required super.isSuspended,
    super.avatarPath,
    super.avatarUrl,
    super.suspensionReason,
    super.business,
  });

  /// Maps the `v_my_profile` columns selected in ProfileRemoteDataSourceImpl,
  /// plus `avatar_url`: the photo's public URL, which the data source adds.
  /// The business columns are null for a client (`is_business` false).
  factory MyProfileModel.fromJson(Map<String, dynamic> json) {
    final isBusiness = json['is_business'] as bool? ?? false;
    return MyProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      isSuspended: json['is_suspended'] as bool? ?? false,
      avatarPath: json['avatar_path'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      suspensionReason: json['suspension_reason'] as String?,
      business: isBusiness
          ? MyProfileBusiness(
              companyName: json['company_name'] as String,
              crNumber: json['cr_number'] as String,
              specializedField: json['specialized_field'] as String,
              verificationStatus: VerificationStatus.fromJson(
                json['verification_status'] as String,
              ),
              city: json['city'] as String?,
            )
          : null,
    );
  }
}
