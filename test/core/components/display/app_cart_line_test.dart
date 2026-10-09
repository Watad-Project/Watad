import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_cart_line.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the product, quantity, price and trailing', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const AppCartLine(
        title: 'حديد تسليح ١٢ مم',
        subtitle: '٢٠ طن',
        priceLabel: '٥٥٬٠٠٠ ر.س',
        trailing: Text('stepper'),
      ),
    );

    expect(find.text('حديد تسليح ١٢ مم'), findsOneWidget);
    expect(find.text('٢٠ طن'), findsOneWidget);
    expect(find.text('٥٥٬٠٠٠ ر.س'), findsOneWidget);
    expect(find.text('stepper'), findsOneWidget);
    expect(find.byType(AppImagePlaceholder), findsOneWidget);
  });
}
