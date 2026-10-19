import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows the message and tries again', (tester) async {
    var retries = 0;
    await pumpComponent(
      tester,
      AppErrorView(message: 'تعذّر الاتصال', onRetry: () => retries++),
    );

    expect(find.text('تعذّر الاتصال'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retries, 1);
  });

  testWidgets('has no retry button without onRetry', (tester) async {
    await pumpComponent(tester, const AppErrorView(message: 'تعذّر الاتصال'));

    expect(find.text('إعادة المحاولة'), findsNothing);
  });
}
