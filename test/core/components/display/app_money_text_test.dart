import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/utils/money.dart';

import '../../../helpers/pump_component.dart';

void main() {
  testWidgets('writes the amount and «ر.س» in Arabic', (tester) async {
    await pumpComponent(tester, const AppMoneyText(Money.halalas(46500000)));

    expect(find.text('٤٦٥٬٠٠٠ ر.س', findRichText: true), findsOneWidget);
  });

  testWidgets('shows halalas only when there are some, in English', (
    tester,
  ) async {
    late BuildContext context;
    await pumpComponent(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const AppMoneyText(Money.halalas(1250));
        },
      ),
      locale: AppLocalization.english,
    );

    expect(find.text('12.50 SAR', findRichText: true), findsOneWidget);
    expect(
      AppMoneyText.format(context, const Money.halalas(46500000)),
      '465,000 SAR',
    );
  });
}
