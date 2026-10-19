import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_otp_input.dart';
import 'package:watad/core/components/inputs/app_phone_field.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_client_page.dart';

import '../../../../../helpers/fake_app_session.dart';
import '../../../../../helpers/fake_auth_repository.dart';
import '../../../../../helpers/fake_client_home_repository.dart';
import '../../../../../helpers/pump_router.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    // The client's navigation opens on its «الرئيسية» tab.
    registerFakeClientHome();
    repository = FakeAuthRepository();
    registerFakeAuthBloc(repository);
    registerFakeSignUpClientBloc(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> openSignUp(
    WidgetTester tester, {
    AppSession? session,
  }) async {
    final router = await pumpAppRouter(
      tester,
      initialLocation: AuthRoutes.signUpClientPath,
      session: session,
    );
    router.goNamed(AuthRoutes.signUpClientName);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('renders sign up page with form and login link', (tester) async {
    await openSignUp(tester);

    expect(find.byType(SignUpClientPage), findsOneWidget);
    expect(find.text('أنشئ حسابك'), findsOneWidget);
    expect(find.text('لديك حساب بالفعل؟'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('tapping login navigates to login screen', (tester) async {
    final router = await openSignUp(tester);

    final loginLink = find.text('تسجيل الدخول');
    await tester.ensureVisible(loginLink);
    await tester.tap(loginLink);
    await tester.pumpAndSettle();

    expect(currentPath(router), AuthRoutes.loginPath);
  });

  testWidgets(
    'tapping terms and privacy policy link shows coming soon snackbar',
    (tester) async {
      await openSignUp(tester);

      final richTextFinder = find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('الشروط وسياسة الخصوصية'),
      );
      await tester.ensureVisible(richTextFinder);

      final richText = tester.widget<RichText>(richTextFinder);
      final textSpan = richText.text as TextSpan;
      final linkSpan = textSpan.children![1] as TextSpan;
      final recognizer = linkSpan.recognizer! as TapGestureRecognizer;
      recognizer.onTap!();
      await tester.pump();

      expect(find.text('قريباً'), findsOneWidget);
    },
  );

  testWidgets('allows both Arabic and English characters in full name field', (
    tester,
  ) async {
    await openSignUp(tester);

    final nameField = find.widgetWithText(AppTextField, 'الاسم الكامل');
    expect(nameField, findsOneWidget);

    await tester.enterText(
      find.descendant(of: nameField, matching: find.byType(TextFormField)),
      'محمد John Doe',
    );
    await tester.pump();

    expect(find.text('محمد John Doe'), findsOneWidget);
  });

  testWidgets(
    'entering OTP when profile is created navigates to client navigation',
    (tester) async {
      repository.saveProfileResult = const Success('created');
      final session = FakeAppSession()..signIn(AppRole.client);
      final router = await openSignUp(tester, session: session);

      final nameField = find.widgetWithText(AppTextField, 'الاسم الكامل');
      await tester.enterText(
        find.descendant(of: nameField, matching: find.byType(TextFormField)),
        'محمد علي',
      );

      final idField = find.widgetWithText(AppTextField, 'رقم الهوية / الإقامة');
      await tester.enterText(
        find.descendant(of: idField, matching: find.byType(TextFormField)),
        '1098765432',
      );

      final emailField = find.widgetWithText(AppTextField, 'البريد الإلكتروني');
      await tester.enterText(
        find.descendant(of: emailField, matching: find.byType(TextFormField)),
        'test@example.com',
      );

      final phoneField = find.byType(AppPhoneField);
      await tester.enterText(
        find.descendant(of: phoneField, matching: find.byType(TextFormField)),
        '512345678',
      );

      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(AppButton, 'أنشئ حساباً');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AppOtpInput), findsOneWidget);

      await tester.enterText(find.byType(AppOtpInput), '123456');
      await tester.pumpAndSettle();

      expect(currentPath(router), ClientNavigationRoutes.navigationPath);
    },
  );

  testWidgets(
    'entering OTP when already_registered does not navigate and displays error',
    (tester) async {
      repository.saveProfileResult = const Success('already_registered');
      final router = await openSignUp(tester);

      final nameField = find.widgetWithText(AppTextField, 'الاسم الكامل');
      await tester.enterText(
        find.descendant(of: nameField, matching: find.byType(TextFormField)),
        'محمد علي',
      );

      final idField = find.widgetWithText(AppTextField, 'رقم الهوية / الإقامة');
      await tester.enterText(
        find.descendant(of: idField, matching: find.byType(TextFormField)),
        '1098765432',
      );

      final emailField = find.widgetWithText(AppTextField, 'البريد الإلكتروني');
      await tester.enterText(
        find.descendant(of: emailField, matching: find.byType(TextFormField)),
        'test@example.com',
      );

      final phoneField = find.byType(AppPhoneField);
      await tester.enterText(
        find.descendant(of: phoneField, matching: find.byType(TextFormField)),
        '512345678',
      );

      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(AppButton, 'أنشئ حساباً');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AppOtpInput), findsOneWidget);

      await tester.enterText(find.byType(AppOtpInput), '123456');
      await tester.pumpAndSettle();

      expect(currentPath(router), AuthRoutes.signUpClientPath);
      expect(find.text('البريد الإلكتروني مسجل مسبقاً'), findsWidgets);
    },
  );
}
