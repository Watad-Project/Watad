/// Every route's name and path, so screens never write a path by hand.
///
/// Navigate by name: `context.goNamed(AppRoutes.loginName)`. Add your
/// constants here, grouped by feature and role (APP_ARCHITECTURE.md §11).
abstract final class AppRoutes {
  // splash / shared
  static const String splashName = 'splash';
  static const String splashPath = '/splash';

  // onboarding / shared
  static const String onboardingName = 'onboarding';
  static const String onboardingPath = '/onboarding';

  // onboarding / contractor
  static const String contractorSpecialtyName = 'contractor-specialty';
  static const String contractorSpecialtyPath =
      '/contractor/onboarding/specialty';

  // auth / shared
  static const String loginName = 'login';
  static const String loginPath = '/auth/login';
  static const String roleSelectionName = 'role-selection';
  static const String roleSelectionPath = '/auth/role';
  static const String signUpClientName = 'sign-up-client';
  static const String signUpClientPath = '/auth/signup/client';
  static const String signUpBusinessName = 'sign-up-business';
  static const String signUpBusinessPath = '/auth/signup/business';

  // business_verification / contractor
  static const String contractorLicenseUploadName = 'contractor-license-upload';
  static const String contractorLicenseUploadPath =
      '/contractor/business-verification/license';

  // business_verification / shared
  static const String verificationStatusName = 'verification-status';
  static const String verificationStatusPath = '/business-verification/status';
}
