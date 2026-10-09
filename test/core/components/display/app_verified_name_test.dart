import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_verified_name.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the name and the verified check, read out as Verified', (
    tester,
  ) async {
    await pumpComponent(tester, const AppVerifiedName(name: 'البناء المتين'));

    expect(find.text('البناء المتين'), findsOneWidget);
    expect(find.bySemanticsLabel('موثّقة'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
