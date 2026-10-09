import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/theme/app_tone.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows a rejection with its reason and action', (tester) async {
    await pumpComponent(
      tester,
      const AppStatusCard(
        tone: AppTone.danger,
        title: 'رُفض الإيصال',
        reasonTitle: 'المبلغ لا يطابق قيمة المرحلة',
        reasonText: 'الفرق ٢٬٠٠٠ ر.س',
        action: Text('رفع إيصال جديد'),
      ),
    );

    for (final text in [
      'رُفض الإيصال',
      'المبلغ لا يطابق قيمة المرحلة',
      'الفرق ٢٬٠٠٠ ر.س',
      'رفع إيصال جديد',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('uses the colors of its tone', (tester) async {
    await pumpComponent(
      tester,
      const AppStatusCard(
        tone: AppTone.success,
        title: 'تم التأكيد',
        subtitle: 'الدفعة مدفوعة · موثّقة',
      ),
    );

    final box = tester.widget<Container>(find.byType(Container).first);
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, AppTone.success.background);
    expect(find.text('الدفعة مدفوعة · موثّقة'), findsOneWidget);
  });
}
