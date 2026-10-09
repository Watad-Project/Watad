import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_cart_group.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the seller, the note and the lines', (tester) async {
    await pumpComponent(
      tester,
      const AppCartGroup(
        title: 'مصنع الرياض للحديد',
        note: 'توصيل خلال ٣ أيام',
        children: [Text('سطر ١'), Text('سطر ٢')],
      ),
    );

    expect(find.text('مصنع الرياض للحديد'), findsOneWidget);
    expect(find.text('توصيل خلال ٣ أيام'), findsOneWidget);
    expect(find.text('سطر ١'), findsOneWidget);
    expect(find.text('سطر ٢'), findsOneWidget);
    // One divider between the two lines.
    expect(find.byType(Divider), findsOneWidget);
  });
}
