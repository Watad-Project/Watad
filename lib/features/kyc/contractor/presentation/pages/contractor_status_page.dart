import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_tone.dart';

class ContractorStatusPage extends StatelessWidget {
  const ContractorStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: context.tr('kyc.contractor.status_title')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppStatusCard(
                tone: AppTone.attention,
                title: context.tr('kyc.contractor.status_pending_title'),
                subtitle: context.tr('kyc.contractor.status_pending_subtitle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
