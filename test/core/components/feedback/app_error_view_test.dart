import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('renders error message and responds to retry button tap', (
    tester,
  ) async {
    var retried = false;
    await pumpComponent(
      tester,
      AppErrorView(
        message: 'Something went wrong',
        onRetry: () => retried = true,
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retried, isTrue);
  });
}
