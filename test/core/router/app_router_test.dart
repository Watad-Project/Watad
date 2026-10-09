import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_not_found_view.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/app_router.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/core/theme/app_theme.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_selection_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_business_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_client_page.dart';
import 'package:watad/features/business_verification/contractor/presentation/pages/contractor_license_upload_page.dart';
import 'package:watad/features/business_verification/shared/presentation/pages/verification_status_page.dart';
import 'package:watad/features/onboarding/contractor/presentation/pages/contractor_specialty_page.dart';
import 'package:watad/features/onboarding/shared/presentation/pages/onboarding_page.dart';
import 'package:watad/features/splash/shared/presentation/pages/splash_page.dart';

import '../../helpers/pump_component.dart';

void main() {
  /// Shows a fresh router in a localized app and returns it.
  Future<GoRouter> pumpRouter(WidgetTester tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      AppLocalization.scope(
        assetLoader: const TestAssetLoader(),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  String currentPath(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('starts on /splash', (tester) async {
    final router = await pumpRouter(tester);

    expect(currentPath(router), AppRoutes.splashPath);
    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('every route name opens its page at its path', (tester) async {
    final router = await pumpRouter(tester);
    final routes = <String, (String, Type)>{
      AppRoutes.splashName: (AppRoutes.splashPath, SplashPage),
      AppRoutes.onboardingName: (AppRoutes.onboardingPath, OnboardingPage),
      AppRoutes.contractorSpecialtyName: (
        AppRoutes.contractorSpecialtyPath,
        ContractorSpecialtyPage,
      ),
      AppRoutes.loginName: (AppRoutes.loginPath, LoginPage),
      AppRoutes.roleSelectionName: (
        AppRoutes.roleSelectionPath,
        RoleSelectionPage,
      ),
      AppRoutes.signUpClientName: (
        AppRoutes.signUpClientPath,
        SignUpClientPage,
      ),
      AppRoutes.signUpBusinessName: (
        AppRoutes.signUpBusinessPath,
        SignUpBusinessPage,
      ),
      AppRoutes.contractorLicenseUploadName: (
        AppRoutes.contractorLicenseUploadPath,
        ContractorLicenseUploadPage,
      ),
      AppRoutes.verificationStatusName: (
        AppRoutes.verificationStatusPath,
        VerificationStatusPage,
      ),
    };

    for (final MapEntry(key: name, value: (path, page)) in routes.entries) {
      router.goNamed(name);
      await tester.pumpAndSettle();
      expect(currentPath(router), path, reason: name);
      expect(find.byType(page), findsOneWidget, reason: name);
    }
  });

  testWidgets('an unknown address shows the not-found page', (tester) async {
    final router = await pumpRouter(tester);

    router.go('/no-such-page');
    await tester.pumpAndSettle();
    expect(find.byType(AppNotFoundView), findsOneWidget);

    await tester.tap(find.text('العودة إلى البداية'));
    await tester.pumpAndSettle();
    expect(find.byType(SplashPage), findsOneWidget);
  });
}
