import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_segmented_tabs.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('reports the tapped segment', (tester) async {
    int? selected;
    await pumpComponent(
      tester,
      AppSegmentedTabs(
        labels: const ['فرص جديدة ٦٠', 'عقودي ٣٠'],
        selectedIndex: 0,
        onChanged: (i) => selected = i,
      ),
    );

    await tester.tap(find.text('عقودي ٣٠'));
    expect(selected, 1);
  });

  testWidgets('segments share the width equally', (tester) async {
    await pumpComponent(
      tester,
      AppSegmentedTabs(
        labels: const ['أ', 'ب'],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
    );

    final widths = [
      for (final label in ['أ', 'ب'])
        tester
            .getRect(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(Expanded),
              ),
            )
            .width,
    ];
    expect(widths[0], widths[1]);
  });
}
