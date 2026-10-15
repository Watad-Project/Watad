import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('renders message, title and triggers action on tap', (
    tester,
  ) async {
    var actionTapped = false;
    await pumpComponent(
      tester,
      AppEmptyView(
        title: 'Empty List',
        message: 'No items available right now.',
        actionLabel: 'Add Item',
        onAction: () => actionTapped = true,
      ),
    );

    expect(find.text('Empty List'), findsOneWidget);
    expect(find.text('No items available right now.'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);

    await tester.tap(find.text('Add Item'));
    expect(actionTapped, isTrue);
  });
}
