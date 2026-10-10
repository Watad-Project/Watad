import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_selection_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_business_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_client_page.dart';

class _FallbackAuthRepository implements AuthRepository {
  const _FallbackAuthRepository();

  @override
  Future<Result<void>> sendOtp({required String email}) async =>
      const Success(null);

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) async => const Success(AuthSession(userId: ''));
}

AuthBloc _createAuthBloc() {
  if (getIt.isRegistered<AuthBloc>()) {
    return getIt<AuthBloc>();
  }
  const repo = _FallbackAuthRepository();
  return AuthBloc(const SendOtpUseCase(repo), const VerifyOtpUseCase(repo));
}

final List<RouteBase> authRoutes = [
  GoRoute(
    name: AppRoutes.loginName,
    path: AppRoutes.loginPath,
    builder: (context, state) => BlocProvider(
      create: (_) => _createAuthBloc(),
      child: const LoginPage(),
    ),
  ),
  GoRoute(
    name: AppRoutes.roleSelectionName,
    path: AppRoutes.roleSelectionPath,
    builder: (context, state) => const RoleSelectionPage(),
  ),
  GoRoute(
    name: AppRoutes.signUpClientName,
    path: AppRoutes.signUpClientPath,
    builder: (context, state) => const SignUpClientPage(),
  ),
  GoRoute(
    name: AppRoutes.signUpBusinessName,
    path: AppRoutes.signUpBusinessPath,
    builder: (context, state) => const SignUpBusinessPage(),
  ),
];
