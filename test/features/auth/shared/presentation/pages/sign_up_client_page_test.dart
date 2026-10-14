import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_client_page.dart';

import '../../../../../helpers/fake_auth_repository.dart';
import '../../../../../helpers/pump_router.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
    registerFakeAuthBloc(repository);
    registerFakeSignUpClientBloc(repository);
  });

  tearDown(getIt.reset);

  Future<GoRouter> openSignUp(WidgetTester tester) async {
    final router = await pumpAppRouter(
      tester,
      initialLocation: AuthRoutes.signUpClientPath,
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
}
