import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('gives the primary action two thirds of the width', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppActionBar(primary: Text('قبول'), secondary: Text('رفض')),
    );

    double widthOf(String text) => tester
        .getSize(
          find.ancestor(of: find.text(text), matching: find.byType(Expanded)),
        )
        .width;
    expect(widthOf('قبول'), closeTo(widthOf('رفض') * 2, 1));
  });

  testWidgets('puts the primary action first (on the right in Arabic)', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppActionBar(primary: Text('قبول'), secondary: Text('رفض')),
    );

    expect(
      tester.getCenter(find.text('قبول')).dx,
      greaterThan(tester.getCenter(find.text('رفض')).dx),
    );
  });
}
