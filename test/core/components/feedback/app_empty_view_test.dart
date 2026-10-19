import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the message under its icon', (tester) async {
    await pumpComponent(
      tester,
      const AppEmptyView(
        message: 'لا توجد طلبات للمراجعة',
        icon: Icons.verified_user_outlined,
      ),
    );

    expect(find.text('لا توجد طلبات للمراجعة'), findsOneWidget);
    expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
  });
}
