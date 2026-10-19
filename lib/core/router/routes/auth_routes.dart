/// The routes of lib/features/auth/shared/. Any feature navigates to them
/// with these names (APP_ARCHITECTURE.md §11).
abstract final class AuthRoutes {
  static const String loginName = 'login';
  static const String loginPath = '/auth/login';

  static const String roleName = 'role';
  static const String rolePath = '/auth/role';

  static const String signUpBusinessName = 'sign-up-business';
  static const String signUpBusinessPath = '/auth/signup/business';

  static const String signUpClientName = 'sign-up-client';
  static const String signUpClientPath = '/auth/signup/client';
}
