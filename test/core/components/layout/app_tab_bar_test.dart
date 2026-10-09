import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_tab_bar.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the tabs and reports taps', (tester) async {
    int? tapped;
    await pumpComponent(
      tester,
      DefaultTabController(
        length: 3,
        child: AppTabBar(
          labels: const ['نظرة عامة', 'سجل الأعمال', 'التقييمات'],
          onTap: (i) => tapped = i,
        ),
      ),
    );

    expect(find.byType(Tab), findsNWidgets(3));
    await tester.tap(find.text('التقييمات'));
    expect(tapped, 2);
  });
}
