import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/features/profile/contractor/presentation/widgets/contractor_business_card.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_overview_body.dart';

/// «منشأتي»: the contractor's account tab (GRA-59). Who they are, their
/// business, and the way to everything about their account.
class ContractorProfilePage extends StatelessWidget {
  const ContractorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: context.tr('profile.contractor.title')),
      body: ProfileOverviewBody(
        businessBuilder: (business) =>
            ContractorBusinessCard(business: business),
      ),
    );
  }
}
