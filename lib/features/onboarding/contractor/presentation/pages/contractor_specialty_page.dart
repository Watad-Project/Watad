import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/onboarding/contractor/domain/entities/contractor_specialty.dart';
import 'package:watad/features/onboarding/contractor/presentation/bloc/contractor_specialty_bloc.dart';

class ContractorSpecialtyPage extends StatelessWidget {
  const ContractorSpecialtyPage({this.onSaved, super.key});

  final void Function(BuildContext context)? onSaved;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('onboarding.contractor_profile_completion_title'),
        onBack: () => context.canPop()
            ? context.pop()
            : context.goNamed(ContractorKycRoutes.licenseName),
      ),
      body: BlocConsumer<ContractorSpecialtyBloc, ContractorSpecialtyState>(
        listener: (context, state) {
          if (state is ContractorSpecialtySaveSuccess) {
            context.showSuccessSnackBar(context.tr('onboarding.save_success'));
            if (onSaved != null) {
              onSaved!(context);
            } else {
              context.goNamed(KycRoutes.statusName);
            }
          } else if (state is ContractorSpecialtySaveFailure) {
            final specialty = state.selectedSpecialty;
            context.showErrorSnackBar(
              context.tr(state.failure.messageKey),
              onRetry: specialty != null
                  ? () => context.read<ContractorSpecialtyBloc>().add(
                      ContractorSpecialtySaved(specialty),
                    )
                  : null,
            );
          }
        },
        builder: (context, state) {
          final selectedSpecialty = state.selectedSpecialty;
          final labels = [
            for (final key in ContractorSpecialty.availableKeys)
              context.tr(key),
          ];
          final selectedIndex = selectedSpecialty == null
              ? -1
              : labels.indexOf(selectedSpecialty);
          final isLoading = state is ContractorSpecialtySaveInProgress;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.tr('onboarding.specialty_title'),
                            style: AppTextStyles.h1,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.tr('onboarding.specialty_subtitle'),
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppFieldLabel(
                            label: context.tr('onboarding.specialty_label'),
                            isRequired: true,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppFilterChips(
                            labels: labels,
                            selectedIndex: selectedIndex,
                            isWrapped: true,
                            onSelected: (index) {
                              context.read<ContractorSpecialtyBloc>().add(
                                ContractorSpecialtySelected(labels[index]),
                              );
                            },
                          ),
                          if (state is ContractorSpecialtySaveFailure) ...[
                            const SizedBox(height: AppSpacing.lg),
                            AppStatusCard(
                              tone: AppTone.danger,
                              title: context.tr('common.retry'),
                              subtitle: context.tr(state.failure.messageKey),
                              action: AppButton(
                                label: context.tr('common.retry'),
                                onPressed: selectedSpecialty != null
                                    ? () => context
                                          .read<ContractorSpecialtyBloc>()
                                          .add(
                                            ContractorSpecialtySaved(
                                              selectedSpecialty,
                                            ),
                                          )
                                    : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: context.tr('onboarding.save_button'),
                    isLoading: isLoading,
                    onPressed: selectedSpecialty != null && !isLoading
                        ? () => context.read<ContractorSpecialtyBloc>().add(
                            ContractorSpecialtySaved(selectedSpecialty),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
