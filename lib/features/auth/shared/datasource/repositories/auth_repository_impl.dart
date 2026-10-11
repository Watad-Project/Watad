import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/auth/shared/datasource/remote/auth_remote_data_source.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Result<bool>> isEmailRegistered(String email) =>
      guardSupabaseCall(() => _remote.isEmailRegistered(email));

  @override
  Future<Result<void>> saveBusinessSignUp(BusinessSignUp data) =>
      guardSupabaseCall(() => _remote.saveBusinessSignUp(data));
}
