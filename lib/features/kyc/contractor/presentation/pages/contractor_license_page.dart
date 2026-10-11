import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_upload_zone.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';

class ContractorLicensePage extends StatelessWidget {
  const ContractorLicensePage({super.key});

  void _onPickCamera(BuildContext context) {
    // Generates sample JPEG image bytes for camera capture in tests/dev
    final dummyBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
    context.read<ContractorLicenseBloc>().add(
      ContractorLicenseFileSelected(
        bytes: dummyBytes,
        fileName: 'contractor_license_camera.jpg',
      ),
    );
  }

  void _onPickFiles(BuildContext context) {
    // Generates sample PDF bytes for file upload in tests/dev
    final dummyBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]);
    context.read<ContractorLicenseBloc>().add(
      ContractorLicenseFileSelected(
        bytes: dummyBytes,
        fileName: 'contractor_license_document.pdf',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContractorLicenseBloc, ContractorLicenseState>(
      listener: (context, state) {
        if (state is ContractorLicenseLoadSuccess) {
          context.goNamed(ContractorKycRoutes.statusName);
        } else if (state is ContractorLicenseLoadFailure) {
          context.showErrorSnackBar(context.tr(state.failure.messageKey));
        }
      },
      builder: (context, state) {
        final isLoading = state is ContractorLicenseLoadInProgress;
        final selectedFileName = switch (state) {
          ContractorLicenseReady(:final fileName) => fileName,
          _ => null,
        };

        return Scaffold(
          appBar: AppTopBar(title: '', onBack: () => context.pop()),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppButton(
                label: context.tr('kyc.contractor.submit_button'),
                isLoading: isLoading,
                onPressed: selectedFileName == null
                    ? null
                    : () => context.read<ContractorLicenseBloc>().add(
                        const ContractorLicenseSubmitted(),
                      ),
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.tr('kyc.contractor.license_step_label'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    context.tr('kyc.contractor.license_title'),
                    style: AppTextStyles.h1,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    context.tr('kyc.contractor.license_subtitle'),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppUploadZone(
                    onTap: () => _onPickFiles(context),
                    label: context.tr('kyc.contractor.upload_zone_title'),
                    subtitle: context.tr('kyc.contractor.upload_zone_hint'),
                  ),
                  if (selectedFileName != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadius.md),
                        ),
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.controlBorder),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              context.tr(
                                'kyc.contractor.file_selected_prefix',
                                namedArgs: {'fileName': selectedFileName},
                              ),
                              style: AppTextStyles.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: context.tr('kyc.contractor.from_camera'),
                          icon: Icons.camera_alt,
                          variant: AppButtonVariant.primary,
                          onPressed: () => _onPickCamera(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          label: context.tr('kyc.contractor.from_files'),
                          icon: Icons.folder_open,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _onPickFiles(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.tr('kyc.contractor.license_footnote'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
