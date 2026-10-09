import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_project_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the project and reports taps', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppProjectCard(
        title: 'فيلا سكنية — حي الياسمين',
        subtitle: 'مؤسسة البناء المتين',
        statusLabel: 'نشط',
        progress: 0.6,
        progressLabel: '٣ من ٥ مهام',
        percentLabel: '٦٠٪',
        dateLabel: 'يناير ← أغسطس ٢٠٢٦',
        amountLabel: '٤٨٠٬٠٠٠ ر.س',
        onTap: () => taps++,
      ),
    );

    for (final text in [
      'فيلا سكنية — حي الياسمين',
      'مؤسسة البناء المتين',
      '٣ من ٥ مهام',
      '٦٠٪',
      'يناير ← أغسطس ٢٠٢٦',
      '٤٨٠٬٠٠٠ ر.س',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.widgetWithText(AppStatusBadge, 'نشط'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.6);

    await tester.tap(find.text('مؤسسة البناء المتين'));
    expect(taps, 1);
  });
}
