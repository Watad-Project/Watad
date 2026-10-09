import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_timeline.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows every item with its marker', (tester) async {
    await pumpComponent(
      tester,
      const AppTimeline(
        items: [
          AppTimelineItem(
            title: 'الهيكل الخرساني',
            subtitle: 'أُنجزت ٢٤ فبراير',
            trailing: '١٢٠٬٠٠٠ ر.س',
            state: AppTimelineState.done,
            tag: Text('معتمدة ومدفوعة'),
          ),
          AppTimelineItem(
            title: 'التمديدات الكهربائية',
            state: AppTimelineState.current,
          ),
          AppTimelineItem(
            title: 'العزل المائي للسطح',
            state: AppTimelineState.upcoming,
          ),
        ],
      ),
    );

    expect(find.text('الهيكل الخرساني'), findsOneWidget);
    expect(find.text('أُنجزت ٢٤ فبراير'), findsOneWidget);
    expect(find.text('١٢٠٬٠٠٠ ر.س'), findsOneWidget);
    expect(find.text('معتمدة ومدفوعة'), findsOneWidget);
    expect(find.text('العزل المائي للسطح'), findsOneWidget);
    // Only the done item has a check.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
