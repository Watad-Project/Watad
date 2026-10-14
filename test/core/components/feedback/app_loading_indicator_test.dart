import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows CircularProgressIndicator with specified size', (
    tester,
  ) async {
    await pumpComponent(tester, const AppLoadingIndicator(size: 40));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final sizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBox.width, 40);
    expect(sizedBox.height, 40);
  });
}
