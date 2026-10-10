import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/auth/shared/datasource/remote/auth_remote_data_source.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] wrapping remote calls with [guardSupabaseCall].
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Result<void>> sendOtp({required String email}) {
    return guardSupabaseCall(() => _remote.sendOtp(email: email));
  }

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) {
    return guardSupabaseCall(
      () => _remote.verifyOtp(email: email, token: token),
    );
  }
}
