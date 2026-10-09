import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_phone_field.dart';
import 'package:watad/core/localization/app_localization.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('groups the digits as 5x xxx xxxx', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpComponent(tester, AppPhoneField(controller: controller));

    await tester.enterText(find.byType(TextFormField), '5012345678999');
    expect(controller.text, '50 123 4567');
  });

  testWidgets('turns Arabic-Indic digits into 0-9', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpComponent(tester, AppPhoneField(controller: controller));

    await tester.enterText(find.byType(TextFormField), '٥٠١٢٣٤٥٦٧');
    expect(controller.text, '50 123 4567');
  });

  testWidgets('shows the country code', (tester) async {
    await pumpComponent(tester, const AppPhoneField(label: 'رقم الجوال'));

    expect(find.text('رقم الجوال'), findsOneWidget);
    expect(find.text(AppPhoneField.countryCode), findsOneWidget);
  });

  testWidgets('puts the country code on the right in Arabic', (tester) async {
    await pumpComponent(tester, const AppPhoneField());

    final width = tester.getSize(find.byType(Scaffold)).width;
    expect(
      tester.getCenter(find.text(AppPhoneField.countryCode)).dx,
      greaterThan(width / 2),
    );
  });

  testWidgets('puts the country code on the left in English', (tester) async {
    await pumpComponent(
      tester,
      const AppPhoneField(),
      locale: AppLocalization.english,
    );

    final width = tester.getSize(find.byType(Scaffold)).width;
    expect(
      tester.getCenter(find.text(AppPhoneField.countryCode)).dx,
      lessThan(width / 2),
    );
  });

  test('fullNumber accepts only 9 digits starting with 5', () {
    expect(AppPhoneField.fullNumber('50 123 4567'), '+966501234567');
    expect(AppPhoneField.fullNumber('40 123 4567'), isNull);
    expect(AppPhoneField.fullNumber('50 123'), isNull);
  });
}
