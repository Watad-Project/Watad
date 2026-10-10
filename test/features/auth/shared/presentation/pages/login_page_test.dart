import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_logo.dart';
import 'package:watad/core/components/inputs/app_otp_input.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/core/theme/app_theme.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_session.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';
import 'package:watad/features/auth/shared/domain/usecases/send_otp_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/auth_routes.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_selection_page.dart';

import '../../../../../helpers/pump_component.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.sendOtpResult = const Success(null),
    this.verifyOtpResult = const Success(AuthSession(userId: 'test-user')),
  });

  Result<void> sendOtpResult;
  Result<AuthSession> verifyOtpResult;

  @override
  Future<Result<void>> sendOtp({required String email}) async => sendOtpResult;

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String token,
  }) async => verifyOtpResult;
}

Future<void> pumpLoginPage(
  WidgetTester tester, {
  Locale locale = AppLocalization.arabic,
}) async {
  EasyLocalization.logger.enableLevels = [];
  final router = GoRouter(
    initialLocation: AppRoutes.loginPath,
    routes: authRoutes,
  );

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: AppLocalization.supportedLocales,
      path: AppLocalization.path,
      fallbackLocale: AppLocalization.fallbackLocale,
      startLocale: locale,
      saveLocale: false,
      assetLoader: const TestAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp.router(
          theme: AppTheme.light,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final getIt = GetIt.instance;

  setUp(() {
    if (getIt.isRegistered<AuthBloc>()) {
      getIt.unregister<AuthBloc>();
    }
    final fakeRepo = FakeAuthRepository();
    getIt.registerFactory(
      () => AuthBloc(SendOtpUseCase(fakeRepo), VerifyOtpUseCase(fakeRepo)),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<AuthBloc>()) {
      getIt.unregister<AuthBloc>();
    }
  });

  testWidgets('renders all login screen elements in Arabic', (tester) async {
    await pumpLoginPage(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(
      find.text('البريد الإلكتروني ثم رمز تحقّق من ٤ أرقام يصلك على بريدك.'),
      findsOneWidget,
    );
    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.byType(AppOtpInput), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'تأكيد'), findsOneWidget);
    expect(find.textContaining('إعادة الإرسال خلال'), findsOneWidget);
    expect(find.text('أنشئ حساباً'), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.widgetWithText(AppButton, 'تأكيد'));
    await tester.pump();

    expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
  });

  testWidgets('shows invalid email error for bad email format', (tester) async {
    await pumpLoginPage(tester);

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.widgetWithText(AppButton, 'تأكيد'));
    await tester.pump();

    expect(find.text('الرجاء إدخال بريد إلكتروني صحيح'), findsOneWidget);
  });

  testWidgets('shows error when OTP is missing or incomplete', (tester) async {
    await pumpLoginPage(tester);

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.widgetWithText(AppButton, 'تأكيد'));
    await tester.pump();

    expect(find.text('رمز التحقق مطلوب'), findsOneWidget);
  });

  testWidgets('countdown ticks and reveals resend button at zero', (
    tester,
  ) async {
    await pumpLoginPage(tester);

    // Initial state shows countdown
    expect(find.textContaining('إعادة الإرسال خلال'), findsOneWidget);

    // Advance 30 seconds to let countdown finish
    await tester.pump(const Duration(seconds: 30));

    expect(find.text('إعادة الإرسال'), findsOneWidget);
  });

  testWidgets('navigates to role selection when clicking create account', (
    tester,
  ) async {
    await pumpLoginPage(tester);

    await tester.ensureVisible(find.text('أنشئ حساباً'));
    await tester.tap(find.text('أنشئ حساباً'));
    await tester.pumpAndSettle();

    expect(find.byType(RoleSelectionPage), findsOneWidget);
  });
}
