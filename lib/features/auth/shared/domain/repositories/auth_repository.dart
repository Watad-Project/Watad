import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';

abstract interface class AuthRepository {
  Future<Result<bool>> isEmailRegistered(String email);

  Future<Result<void>> saveBusinessSignUp(BusinessSignUp data);
}
