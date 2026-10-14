import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows error message and calls onRetry when tapped', (
    tester,
  ) async {
    var retries = 0;
    await pumpComponent(
      tester,
      AppErrorView(message: 'Something went wrong', onRetry: () => retries++),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    // Button label is 'إعادة المحاولة' in Arabic or custom
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retries, 1);
  });
}
