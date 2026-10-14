import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_radio_row.dart';
import 'package:watad/features/projects/client/presentation/pages/client_post_project_address_page.dart';

import '../../../../../helpers/pump_component.dart';

void main() {
  testWidgets('renders address page with saved addresses and enable button', (
    tester,
  ) async {
    await pumpLocalizedApp(tester, const ClientPostProjectAddressPage());

    expect(
      find.byKey(const Key('client_post_project_new_location_button')),
      findsOneWidget,
    );
    expect(find.byType(AppRadioRow), findsWidgets);
    expect(
      find.byKey(const Key('client_post_project_use_address_button')),
      findsOneWidget,
    );

    final button = tester.widget<AppButton>(
      find.byKey(const Key('client_post_project_use_address_button')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('tapping another address updates selected state', (tester) async {
    await pumpLocalizedApp(tester, const ClientPostProjectAddressPage());

    final rows = find.byType(AppRadioRow);
    expect(rows, findsWidgets);

    // Tap second radio row
    await tester.tap(rows.at(1));
    await tester.pumpAndSettle();

    final firstRow = tester.widget<AppRadioRow>(rows.at(0));
    final secondRow = tester.widget<AppRadioRow>(rows.at(1));

    expect(firstRow.selected, isFalse);
    expect(secondRow.selected, isTrue);
  });
}
