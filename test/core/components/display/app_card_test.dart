import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_card.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('reports taps when tappable', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppCard(onTap: () => taps++, child: const Text('بطاقة')),
    );

    await tester.tap(find.text('بطاقة'));
    expect(taps, 1);
  });

  testWidgets('has no ink effect without onTap', (tester) async {
    await pumpComponent(tester, const AppCard(child: Text('بطاقة')));

    expect(find.byType(InkWell), findsNothing);
  });
}
