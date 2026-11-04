import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/theme/app_tone.dart';

/// «وضع تجريبي — لا يتم خصم أي مبلغ», always in view while paying, so
/// nobody types a real card thinking they'll be charged.
class MarketplaceDemoNote extends StatelessWidget {
  const MarketplaceDemoNote({super.key});

  @override
  Widget build(BuildContext context) {
    return AppIconTag(
      key: const Key('payment_demo_note'),
      label: context.tr('marketplace.payment.demo_note'),
      icon: Icons.science_outlined,
      tone: AppTone.attention,
    );
  }
}
