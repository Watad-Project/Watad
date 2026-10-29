import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_key_value_list.dart';
import 'package:watad/core/components/display/app_verified_name.dart';
import 'package:watad/core/components/layout/app_menu_row.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_specialty_text.dart';

/// The business part of «منشأتي» (GRA-59): the company name, with the
/// verified check once verified, the CR number, the specialty, and the
/// verification status.
///
/// While the business is unverified or rejected, the status row opens the
/// license upload (`ContractorKycRoutes.licenseName`), which asks for
/// verification again.
class ContractorBusinessCard extends StatelessWidget {
  const ContractorBusinessCard({required this.business, super.key});

  final MyProfileBusiness business;

  @override
  Widget build(BuildContext context) {
    final status = business.verificationStatus;
    final canRequest =
        status == VerificationStatus.unverified ||
        status == VerificationStatus.rejected;
    final specialty = ProfileSpecialtyText.of(
      context,
      business.specializedField,
    );
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (status == VerificationStatus.verified)
                  AppVerifiedName(name: business.companyName)
                else
                  Text(business.companyName, style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.sm),
                AppKeyValueList(
                  rows: [
                    AppKeyValueRow(
                      label: context.tr('profile.contractor.cr_number'),
                      value: business.crNumber,
                      isMonospace: true,
                    ),
                    AppKeyValueRow(
                      label: context.tr('profile.contractor.specialty'),
                      value:
                          specialty ??
                          context.tr('profile.contractor.no_specialty'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          AppMenuRow(
            key: const Key('contractor_profile_status'),
            icon: Icons.verified_user_outlined,
            label: context.tr('profile.contractor.status_title'),
            subtitle: canRequest
                ? context.tr('profile.contractor.request_verification')
                : null,
            tag: context.tr(_statusKey(status)),
            tagTone: _toneOf(status),
            onTap: canRequest ? () => _requestVerification(context) : null,
          ),
        ],
      ),
    );
  }

  /// Opens the license upload. After an upload, the KYC flow goes on to its
  /// status page (`goNamed`), so the contractor doesn't come back here; this
  /// reload runs when they back out without uploading.
  Future<void> _requestVerification(BuildContext context) async {
    final bloc = context.read<ProfileOverviewBloc>();
    await context.pushNamed(ContractorKycRoutes.licenseName);
    bloc.add(const ProfileOverviewFetched());
  }

  static String _statusKey(VerificationStatus status) => switch (status) {
    VerificationStatus.verified => 'profile.contractor.status.verified',
    VerificationStatus.pending => 'profile.contractor.status.pending',
    VerificationStatus.unverified => 'profile.contractor.status.unverified',
    VerificationStatus.rejected => 'profile.contractor.status.rejected',
    VerificationStatus.suspended => 'profile.contractor.status.suspended',
  };

  static AppTone _toneOf(VerificationStatus status) => switch (status) {
    VerificationStatus.verified => AppTone.success,
    VerificationStatus.pending => AppTone.attention,
    VerificationStatus.unverified => AppTone.neutral,
    VerificationStatus.rejected ||
    VerificationStatus.suspended => AppTone.danger,
  };
}
