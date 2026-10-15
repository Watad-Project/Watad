import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_role.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/role_page.dart';

import '../../../../../helpers/pump_component.dart';

void main() {
  Widget buildTestPage({
    RoleBloc? bloc,
    void Function(BuildContext context, AuthRole role)? onContinue,
  }) {
    return BlocProvider<RoleBloc>(
      create: (_) => bloc ?? RoleBloc(),
      child: RolePage(onContinue: onContinue),
    );
  }

  testWidgets('renders title, subtitle, cards, and continue button in Arabic', (
    tester,
  ) async {
    await pumpLocalizedApp(tester, buildTestPage());

    expect(find.text('كيف تستخدم وتد؟'), findsOneWidget);
    expect(
      find.text('يحدّد اختيارك الشاشات التي تدخل إليها بعد التحقق.'),
      findsOneWidget,
    );
    expect(find.text('عميل'), findsOneWidget);
    expect(find.text('أملك عقاراً وأبحث عن مقاول.'), findsOneWidget);
    expect(
      find.text('لا يلزم أي مستند — رمز التحقق يكفي للدخول'),
      findsOneWidget,
    );
    expect(find.text('مقاول'), findsOneWidget);
    expect(find.text('منشأة مقاولات تبحث عن مشاريع.'), findsOneWidget);
    expect(
      find.text('المستند المطلوب: رخصة مقاول — إلزامي قبل تقديم أي عرض'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'متابعة'), findsOneWidget);
  });

  testWidgets('renders translated strings in English', (tester) async {
    await pumpLocalizedApp(
      tester,
      buildTestPage(),
      locale: AppLocalization.english,
    );

    expect(find.text('How do you use Watad?'), findsOneWidget);
    expect(
      find.text(
        'Your choice determines which screens you access after verification.',
      ),
      findsOneWidget,
    );
    expect(find.text('Client'), findsOneWidget);
    expect(
      find.text('I own a property and am looking for a contractor.'),
      findsOneWidget,
    );
    expect(find.text('Contractor'), findsOneWidget);
    expect(
      find.text('A contracting business looking for projects.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Continue'), findsOneWidget);
  });

  testWidgets('toggles selected role when cards are tapped', (tester) async {
    await pumpLocalizedApp(tester, buildTestPage());

    final bloc = tester.element(find.byType(RolePage)).read<RoleBloc>();
    expect((bloc.state as RoleSelectionState).selectedRole, AuthRole.client);

    // Tap contractor card
    await tester.tap(find.text('مقاول'));
    await tester.pump();
    expect(
      (bloc.state as RoleSelectionState).selectedRole,
      AuthRole.contractor,
    );

    // Tap client card back
    await tester.tap(find.text('عميل'));
    await tester.pump();
    expect((bloc.state as RoleSelectionState).selectedRole, AuthRole.client);
  });

  testWidgets('tapping continue triggers onContinue with the chosen role', (
    tester,
  ) async {
    AuthRole? continuedRole;
    await pumpLocalizedApp(
      tester,
      buildTestPage(
        onContinue: (context, role) {
          continuedRole = role;
        },
      ),
    );

    // Continue with default (Client)
    await tester.tap(find.widgetWithText(AppButton, 'متابعة'));
    await tester.pumpAndSettle();
    expect(continuedRole, AuthRole.client);

    // Select Contractor and continue
    await tester.tap(find.text('مقاول'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'متابعة'));
    await tester.pumpAndSettle();
    expect(continuedRole, AuthRole.contractor);
  });
}
