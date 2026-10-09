import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_address_card.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the address and reports both actions', (tester) async {
    final actions = <String>[];
    await pumpComponent(
      tester,
      AppAddressCard(
        title: 'المنزل',
        address: 'الرياض · النرجس · طريق الأمير سلمان · 7421',
        defaultLabel: 'افتراضي',
        editLabel: 'تعديل على الخريطة',
        onEdit: () => actions.add('edit'),
        deleteLabel: 'حذف',
        onDelete: () => actions.add('delete'),
      ),
    );

    expect(find.text('افتراضي'), findsOneWidget);
    expect(
      find.text('الرياض · النرجس · طريق الأمير سلمان · 7421'),
      findsOneWidget,
    );
    await tester.tap(find.text('تعديل على الخريطة'));
    await tester.tap(find.text('حذف'));
    expect(actions, ['edit', 'delete']);
  });

  testWidgets('has no badge when it is not the default', (tester) async {
    await pumpComponent(
      tester,
      AppAddressCard(
        title: 'العمل',
        address: 'جدة',
        editLabel: 'تعديل',
        onEdit: () {},
        deleteLabel: 'حذف',
        onDelete: () {},
      ),
    );

    expect(find.text('افتراضي'), findsNothing);
  });
}
