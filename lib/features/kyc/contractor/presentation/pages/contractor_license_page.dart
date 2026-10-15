import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_upload_zone.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';

class ContractorLicensePage extends StatelessWidget {
  const ContractorLicensePage({
    super.key,
    this.onPickCamera,
    this.onPickFiles,
    this.onSuccess,
  });

  final Future<void> Function(BuildContext context)? onPickCamera;
  final Future<void> Function(BuildContext context)? onPickFiles;
  final void Function(BuildContext context)? onSuccess;

  Future<void> _defaultPickCamera(BuildContext context) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (context.mounted) {
        context.showErrorSnackBar(
          context.tr('kyc.contractor.camera_permission_required'),
        );
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final fileName = photo.name.isNotEmpty
            ? photo.name
            : 'license_${DateTime.now().millisecondsSinceEpoch}.jpg';
        if (context.mounted) {
          context.read<ContractorLicenseBloc>().add(
            ContractorLicenseFileSelected(bytes: bytes, fileName: fileName),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        context.showErrorSnackBar(context.tr('errors.unknown'));
      }
    }
  }

  Future<void> _defaultPickFiles(BuildContext context) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        compressionQuality: 80,
      );

      if (files.isEmpty) {
        return;
      }

      final file = files.first;
      final bytes = await file.readAsBytes();

      if (context.mounted) {
        context.read<ContractorLicenseBloc>().add(
          ContractorLicenseFileSelected(bytes: bytes, fileName: file.name),
        );
      }
    } catch (_) {
      if (context.mounted) {
        context.showErrorSnackBar(context.tr('errors.unknown'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContractorLicenseBloc, ContractorLicenseState>(
      listener: (context, state) {
        if (state is ContractorLicenseLoadSuccess) {
          context.showSuccessSnackBar(
            context.tr('kyc.contractor.upload_success'),
          );
          if (onSuccess != null) {
            onSuccess!(context);
          } else {
            context.pushNamed(KycRoutes.statusName);
          }
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
          appBar: AppTopBar(
            title: '',
            onBack: () => context.canPop()
                ? context.pop()
                : context.goNamed(AuthRoutes.signUpBusinessName),
          ),
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
                    onTap: () => (onPickFiles ?? _defaultPickFiles)(context),
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
                          onPressed: () =>
                              (onPickCamera ?? _defaultPickCamera)(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          label: context.tr('kyc.contractor.from_files'),
                          icon: Icons.folder_open,
                          variant: AppButtonVariant.secondary,
                          onPressed: () =>
                              (onPickFiles ?? _defaultPickFiles)(context),
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
