import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/datasource/models/auth_session_model.dart';
import 'package:watad/features/auth/shared/datasource/remote/auth_remote_data_source.dart';
import 'package:watad/features/auth/shared/datasource/repositories/auth_repository_impl.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/entities/verify_otp_params.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  Object? errorToThrow;
  AuthSessionModel? sessionToReturn;

  @override
  Future<AuthSessionModel?> signUp({
    required String email,
    String? password,
    String? phone,
    Map<String, dynamic>? data,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return sessionToReturn;
  }

  @override
  Future<void> sendSignUpOtp(String email) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }

  @override
  Future<void> sendOtp({
    required String email,
    bool shouldCreateUser = false,
  }) async {}

  @override
  Future<AuthSessionModel> verifyOtp({
    required String email,
    required String token,
  }) async =>
      sessionToReturn ?? const AuthSessionModel(userId: 'u1', email: 'e1');

  @override
  Future<AuthSessionModel> verifySignUpOtp(VerifyOtpParams params) async =>
      sessionToReturn ?? const AuthSessionModel(userId: 'u1', email: 'e1');

  @override
  Future<String> saveProfile(SignUpProfile profile) async => 'created';

  @override
  Future<void> signOut() async {}

  @override
  Future<void> saveBusinessSignUp(BusinessSignUp data) async {}
}

void main() {
  late _FakeAuthRemoteDataSource remote;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = _FakeAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remote);
  });

  group('AuthRepositoryImpl.signUp', () {
    test('returns Success with AuthSession when sign up succeeds', () async {
      remote.sessionToReturn = const AuthSessionModel(
        userId: 'user-123',
        email: 'new@watad.sa',
      );

      final result = await repository.signUp(
        email: 'new@watad.sa',
        password: 'password123',
      );

      expect(result, isA<Success<AuthSession?>>());
      expect((result as Success<AuthSession?>).data?.userId, 'user-123');
    });

    test('maps AuthException user_already_exists to AuthFailure with auth.account_already_exists', () async {
      remote.errorToThrow = const AuthException(
        'User already registered',
        statusCode: '422',
        code: 'user_already_exists',
      );

      final result = await repository.signUp(
        email: 'existing@watad.sa',
        password: 'password123',
      );

      expect(result, isA<Failed<AuthSession?>>());
      final failure = (result as Failed<AuthSession?>).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.messageKey, 'auth.account_already_exists');
    });
  });

  group('AuthRepositoryImpl.sendSignUpOtp', () {
    test('returns Success when sending OTP succeeds', () async {
      final result = await repository.sendSignUpOtp('new@watad.sa');
      expect(result, isA<Success<void>>());
    });

    test('maps AuthException user_already_exists to AuthFailure with auth.account_already_exists', () async {
      remote.errorToThrow = const AuthException(
        'User already registered',
        statusCode: '422',
        code: 'user_already_exists',
      );

      final result = await repository.sendSignUpOtp('existing@watad.sa');

      expect(result, isA<Failed<void>>());
      final failure = (result as Failed<void>).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.messageKey, 'auth.account_already_exists');
    });
  });
}
