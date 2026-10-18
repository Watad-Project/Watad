import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('reports the tapped chip', (tester) async {
    int? selected;
    await pumpComponent(
      tester,
      AppFilterChips(
        labels: const ['الكل', 'حديد', 'خرسانة', 'فائض'],
        selectedIndex: 0,
        onSelected: (i) => selected = i,
      ),
    );

    await tester.tap(find.text('خرسانة'));
    expect(selected, 2);
  });

  testWidgets('every chip has a 48 high tap target', (tester) async {
    await pumpComponent(
      tester,
      AppFilterChips(
        labels: const ['الكل', 'حديد'],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
    );

    expect(tester.getSize(find.byType(AppFilterChips)).height, 48);
  });

  testWidgets('renders Wrap when isWrapped is true', (tester) async {
    int? selected;
    await pumpComponent(
      tester,
      AppFilterChips(
        labels: const ['مقاولات عامة', 'تشطيبات'],
        selectedIndex: 1,
        isWrapped: true,
        onSelected: (i) => selected = i,
      ),
    );

    await tester.tap(find.text('مقاولات عامة'));
    expect(selected, 0);
  });
}
