import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the label and the translated required mark', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppFieldLabel(label: 'التفاصيل', isRequired: true),
    );

    expect(find.text('التفاصيل'), findsOneWidget);
    expect(find.text('إلزامي'), findsOneWidget);
  });

  testWidgets('has no required mark by default', (tester) async {
    await pumpComponent(tester, const AppFieldLabel(label: 'التفاصيل'));

    expect(find.text('إلزامي'), findsNothing);
  });
}
