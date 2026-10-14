import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows message, title and triggers action', (tester) async {
    var actions = 0;
    await pumpComponent(
      tester,
      AppEmptyView(
        title: 'Empty Title',
        message: 'No items found',
        actionLabel: 'Add Item',
        onAction: () => actions++,
      ),
    );

    expect(find.text('Empty Title'), findsOneWidget);
    expect(find.text('No items found'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);

    await tester.tap(find.text('Add Item'));
    expect(actions, 1);
  });
}
