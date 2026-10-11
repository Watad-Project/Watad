import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';

class BusinessSignUpModel extends BusinessSignUp {
  const BusinessSignUpModel({
    required super.companyName,
    required super.crNumber,
    required super.email,
    required super.phone,
    super.role = 'contractor',
  });

  factory BusinessSignUpModel.fromJson(Map<String, dynamic> json) {
    return BusinessSignUpModel(
      companyName: json['company_name'] as String,
      crNumber: json['cr_number'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String? ?? 'contractor',
    );
  }
}
