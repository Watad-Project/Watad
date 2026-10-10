import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_otp_input.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/presentation/pages/login_page.dart';

import '../../../../../helpers/fake_auth_repository.dart';
import '../../../../../helpers/pump_router.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
    registerFakeAuthBloc(repository);
  });

  tearDown(getIt.reset);

  /// Opens the login page through the real router, in Arabic.
  Future<GoRouter> openLogin(WidgetTester tester) async {
    final router = await pumpAppRouter(tester);
    router.goNamed(AuthRoutes.loginName);
    await tester.pumpAndSettle();
    return router;
  }

  final emailField = find.descendant(
    of: find.byType(AppTextField),
    matching: find.byType(TextFormField),
  );
  final loginButton = find.widgetWithText(AppButton, 'تسجيل الدخول');
  final confirmButton = find.widgetWithText(AppButton, 'تأكيد');

  Future<void> sendCode(WidgetTester tester) async {
    await tester.enterText(emailField, 'user@watad.sa');
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the login screen, with email field and login button', (
    tester,
  ) async {
    await openLogin(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(loginButton, findsOneWidget);
    expect(
      find.text('البريد الإلكتروني ثم رمز تحقّق من ٦ أرقام يصلك على بريدك.'),
      findsOneWidget,
    );
    expect(find.byType(AppOtpInput), findsNothing);
    expect(find.textContaining('إعادة الإرسال'), findsNothing);
    expect(find.text('أنشئ حساباً'), findsOneWidget);
  });

  testWidgets('login with an empty email shows the email error', (
    tester,
  ) async {
    await openLogin(tester);

    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump();

    expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
    expect(repository.sentTo, isEmpty);
  });

  testWidgets(
    'login sends the code, reveals otp boxes, and counts down to resend',
    (tester) async {
      await openLogin(tester);

      await sendCode(tester);

      expect(repository.sentTo, ['user@watad.sa']);
      expect(
        find.text('تم إرسال رمز التحقق إلى بريدك الإلكتروني'),
        findsOneWidget,
      );
      expect(confirmButton, findsOneWidget);
      expect(find.textContaining('إعادة الإرسال خلال'), findsOneWidget);
      final boxes = tester.widget<AppOtpInput>(find.byType(AppOtpInput));
      expect(boxes.length, 6);
      expect(boxes.enabled, true);

      await tester.pump(const Duration(seconds: 61));
      await tester.pump();

      expect(find.text('إعادة الإرسال'), findsOneWidget);
    },
  );

  testWidgets('a wrong code shows the code error under the boxes', (
    tester,
  ) async {
    repository.verifyOtpResult = const Failed(AuthFailure());
    await openLogin(tester);
    await sendCode(tester);

    await tester.enterText(find.byType(AppOtpInput), '482910');
    await tester.pump();
    await tester.pump();

    expect(repository.checked, [('user@watad.sa', '482910')]);
    expect(find.text('رمز التحقق غير صحيح أو منتهي الصلاحية'), findsOneWidget);
  });

  testWidgets('tapping confirm with an empty code shows the otp error', (
    tester,
  ) async {
    await openLogin(tester);
    await sendCode(tester);

    await tester.tap(confirmButton);
    await tester.pump();
    await tester.pump();

    expect(find.text('رمز التحقق مطلوب'), findsOneWidget);
    expect(repository.checked, isEmpty);
  });
}
