import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/auth/shared/presentation/widgets/role_card.dart';

import '../../../../../helpers/pump_component.dart';

void main() {
  testWidgets('displays title, description, and note', (tester) async {
    await pumpComponent(
      tester,
      RoleCard(
        title: 'عميل',
        description: 'أملك عقاراً وأبحث عن مقاول.',
        note: 'لا يلزم أي مستند — رمز التحقق يكفي للدخول',
        icon: Icons.person_outline,
        selected: false,
        onTap: () {},
      ),
    );

    expect(find.text('عميل'), findsOneWidget);
    expect(find.text('أملك عقاراً وأبحث عن مقاول.'), findsOneWidget);
    expect(
      find.text('لا يلزم أي مستند — رمز التحقق يكفي للدخول'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('reports tap when tapped', (tester) async {
    var tapped = false;
    await pumpComponent(
      tester,
      RoleCard(
        title: 'مقاول',
        description: 'منشأة مقاولات تبحث عن مشاريع.',
        note: 'المستند المطلوب: رخصة مقاول',
        selected: false,
        onTap: () => tapped = true,
      ),
    );

    await tester.tap(find.text('مقاول'));
    expect(tapped, isTrue);
  });

  testWidgets('shows check mark when selected', (tester) async {
    await pumpComponent(
      tester,
      RoleCard(
        title: 'عميل',
        description: 'الوصف',
        note: 'ملاحظة',
        selected: true,
        onTap: () {},
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('does not show check mark when unselected', (tester) async {
    await pumpComponent(
      tester,
      RoleCard(
        title: 'عميل',
        description: 'الوصف',
        note: 'ملاحظة',
        selected: false,
        onTap: () {},
      ),
    );

    expect(find.byIcon(Icons.check), findsNothing);
  });
}
