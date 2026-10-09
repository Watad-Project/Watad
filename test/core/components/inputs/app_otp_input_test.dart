import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/inputs/app_otp_input.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('renders AppOtpInput and enters code', (tester) async {
    String? entered;
    await pumpComponent(
      tester,
      AppOtpInput(onCompleted: (val) => entered = val),
    );

    expect(find.byType(AppOtpInput), findsOneWidget);
    await tester.enterText(find.byType(AppOtpInput), '1234');
    expect(entered, '1234');
  });

  testWidgets('displays error text', (tester) async {
    await pumpComponent(tester, const AppOtpInput(errorText: 'رمز غير صحيح'));

    expect(find.text('رمز غير صحيح'), findsOneWidget);
  });
}
