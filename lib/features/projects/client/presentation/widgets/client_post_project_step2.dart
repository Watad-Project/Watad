import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_photo_tile.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_dropdown.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/inputs/app_radio_row.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_step_progress.dart';
import 'package:watad/core/router/routes/location_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';

/// Step 2 of the post-project flow: project details (with deed & repairs variants).
class ClientPostProjectStep2 extends StatefulWidget {
  const ClientPostProjectStep2({
    super.key,
    required this.state,
    required this.onTypeChanged,
    required this.onScopeChanged,
    required this.onMinBudgetChanged,
    required this.onMaxBudgetChanged,
    required this.onLocationChanged,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    this.onPickPhoto,
  });

  final ClientPostProjectState state;
  final ValueChanged<ClientProjectType> onTypeChanged;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<Money?> onMinBudgetChanged;
  final ValueChanged<Money?> onMaxBudgetChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onPhotoAdded;
  final ValueChanged<int> onPhotoRemoved;
  final Future<void> Function(BuildContext context)? onPickPhoto;

  @override
  State<ClientPostProjectStep2> createState() => _ClientPostProjectStep2State();
}

class _ClientPostProjectStep2State extends State<ClientPostProjectStep2> {
  late final TextEditingController _scopeController;
  late final TextEditingController _minBudgetController;
  late final TextEditingController _maxBudgetController;

  @override
  void initState() {
    super.initState();
    _scopeController = TextEditingController(text: widget.state.scopeOfWork);
    _minBudgetController = TextEditingController(
      text: widget.state.minBudget != null
          ? _formatNumber(widget.state.minBudget!)
          : '',
    );
    _maxBudgetController = TextEditingController(
      text: widget.state.maxBudget != null
          ? _formatNumber(widget.state.maxBudget!)
          : '',
    );
  }

  @override
  void dispose() {
    _scopeController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  String _formatNumber(Money value) {
    return value.sar.toInt().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
  }

  int? _parseNumber(String text) {
    final clean = text.replaceAll(',', '').replaceAll(' ', '').trim();
    if (clean.isEmpty) return null;
    return int.tryParse(clean);
  }

  Future<void> _handlePickPhoto() async {
    if (widget.onPickPhoto != null) {
      await widget.onPickPhoto!(context);
      return;
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('projects.client.pick_photo_title'),
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: context.tr('projects.client.pick_photo_camera'),
                  icon: Icons.camera_alt_outlined,
                  variant: AppButtonVariant.primary,
                  onPressed: () async {
                    Navigator.of(bottomSheetContext).pop();
                    await _pickFromSource(ImageSource.camera);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: context.tr('projects.client.pick_photo_gallery'),
                  icon: Icons.photo_library_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    Navigator.of(bottomSheetContext).pop();
                    await _pickFromSource(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (photo != null) {
        widget.onPhotoAdded(photo.path);
      }
    } catch (_) {}
  }

  void _showAddAddressSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final buildingCtrl = TextEditingController();
    final postalCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsetsDirectional.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            start: AppSpacing.md,
            end: AppSpacing.md,
            top: AppSpacing.lg,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('projects.client.add_address_button'),
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    key: const Key('client_post_project_sheet_pick_map_button'),
                    label: context.tr('projects.client.address_new_on_map'),
                    icon: Icons.map_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      Navigator.of(bottomSheetContext).pop();
                      final result = await context.pushNamed<dynamic>(
                        LocationRoutes.locationName,
                      );
                      if (result is String && result.trim().isNotEmpty) {
                        widget.onLocationChanged(result);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppFieldLabel(
                    label: context.tr('projects.client.address_name_label'),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AppTextField(
                    controller: nameCtrl,
                    hint: context.tr('projects.client.address_name_hint'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppFieldLabel(
                              label: context.tr(
                                'projects.client.address_city_label',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            AppTextField(
                              controller: cityCtrl,
                              hint: context.tr(
                                'projects.client.address_city_hint',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppFieldLabel(
                              label: context.tr(
                                'projects.client.address_district_label',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            AppTextField(
                              controller: districtCtrl,
                              hint: context.tr(
                                'projects.client.address_district_hint',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppFieldLabel(
                    label: context.tr('projects.client.address_street_label'),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  AppTextField(
                    controller: streetCtrl,
                    hint: context.tr('projects.client.address_street_hint'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppFieldLabel(
                              label: context.tr(
                                'projects.client.address_building_number_label',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            AppTextField(
                              controller: buildingCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              hint: '4210',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppFieldLabel(
                              label: context.tr(
                                'projects.client.address_postal_code_label',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            AppTextField(
                              controller: postalCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(5),
                              ],
                              hint: '13324',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    key: const Key('submit_new_address_button'),
                    label: context.tr('projects.client.address_save_button'),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final city = cityCtrl.text.trim();
                      final district = districtCtrl.text.trim();
                      final street = streetCtrl.text.trim();
                      final building = buildingCtrl.text.trim();
                      final postal = postalCtrl.text.trim();

                      if (city.isNotEmpty &&
                          building.length == 4 &&
                          postal.length == 5) {
                        Navigator.of(bottomSheetContext).pop();
                        context.read<ClientPostProjectBloc>().add(
                          ClientPostProjectAddressCreated(
                            name: name.isNotEmpty
                                ? name
                                : context.tr(
                                    'projects.client.address_default_name',
                                  ),
                            city: city,
                            district: district,
                            street: street,
                            buildingNumber: building,
                            postalCode: postal,
                          ),
                        );
                      }
                    },
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

  void _showAddressSelectionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('projects.client.saved_addresses_title'),
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final address in widget.state.savedAddresses) ...[
                          AppRadioRow(
                            key: ValueKey('addr_radio_${address.id}'),
                            title: address.name,
                            subtitle: address.formattedAddress,
                            selected:
                                widget.state.selectedAddress?.id == address.id,
                            onTap: () {
                              context.read<ClientPostProjectBloc>().add(
                                ClientPostProjectAddressSelected(address),
                              );
                              widget.onLocationChanged(
                                address.formattedAddress,
                              );
                              Navigator.of(bottomSheetContext).pop();
                            },
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: context.tr('projects.client.add_address_button'),
                  icon: Icons.add_location_alt_outlined,
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    Navigator.of(bottomSheetContext).pop();
                    _showAddAddressSheet(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDeedRequired = state.requiresDeed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppStepProgress(current: 2, total: state.totalSteps),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('projects.client.details_title'),
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: AppSpacing.md),

          // Project Type Selector (compact)
          AppFieldLabel(
            label: context.tr('projects.client.project_type_label'),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppDropdown<ClientProjectType>(
            value: state.projectType,
            hint: context.tr('projects.client.project_type_placeholder'),
            options: [
              for (final type in ClientProjectType.values)
                AppDropdownOption<ClientProjectType>(
                  value: type,
                  title: context.tr(type.titleKey),
                  subtitle: context.tr(type.hintKey),
                  tag: context.tr(type.tagKey),
                ),
            ],
            onChanged: (type) {
              widget.onTypeChanged(type);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Scope of Work
          AppFieldLabel(
            label: context.tr('projects.client.scope_of_work_label'),
            isRequired: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: _scopeController,
            maxLines: 4,
            hint: isDeedRequired
                ? context.tr('projects.client.scope_of_work_hint_deed')
                : context.tr('projects.client.scope_of_work_hint_repairs'),
            onChanged: widget.onScopeChanged,
          ),
          const SizedBox(height: AppSpacing.md),

          // Budget (Min & Max in SAR)
          AppFieldLabel(label: context.tr('projects.client.budget_label')),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _minBudgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  hint: context.tr('projects.client.budget_min_hint'),
                  onChanged: (text) {
                    final parsed = _parseNumber(text);
                    widget.onMinBudgetChanged(
                      parsed != null ? Money.fromSar(parsed) : null,
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _maxBudgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  hint: context.tr('projects.client.budget_max_hint'),
                  onChanged: (text) {
                    final parsed = _parseNumber(text);
                    widget.onMaxBudgetChanged(
                      parsed != null ? Money.fromSar(parsed) : null,
                    );
                  },
                ),
              ),
            ],
          ),
          if (!state.isBudgetValid) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.tr('projects.client.budget_error_min_greater'),
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Project Location (Loaded from Supabase)
          AppFieldLabel(
            label: context.tr('projects.client.location_label'),
            isRequired: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (state.isLoadingAddresses) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.lg),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ] else if (state.savedAddresses.isEmpty) ...[
            AppStatusCard(
              key: const Key('client_post_project_no_address_card'),
              tone: AppTone.attention,
              title: context.tr('projects.client.no_addresses_found_title'),
              subtitle: context.tr('projects.client.no_addresses_found_desc'),
              action: AppButton(
                key: const Key('client_post_project_add_address_button'),
                label: context.tr('projects.client.add_address_button'),
                icon: Icons.add_location_alt_outlined,
                onPressed: () => _showAddAddressSheet(context),
              ),
            ),
          ] else ...[
            _LocationCard(
              address:
                  state.locationAddress ??
                  state.selectedAddress?.formattedAddress ??
                  state.savedAddresses.first.formattedAddress,
              onChangeTap: () => _showAddressSelectionSheet(context),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Variant A: Photos row (if deed required)
          if (isDeedRequired) ...[
            AppFieldLabel(label: context.tr('projects.client.photos_label')),
            const SizedBox(height: AppSpacing.xs),
            _PhotosSection(
              photos: state.photos,
              onAddTap: _handlePickPhoto,
              onRemoveTap: widget.onPhotoRemoved,
            ),
          ] else ...[
            // Variant B: Info banner (if repairs / no deed)
            AppStatusCard(
              tone: AppTone.success,
              title: context.tr('projects.client.no_deed_banner_title'),
              subtitle: context.tr('projects.client.no_deed_banner_subtitle'),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.address, required this.onChangeTap});

  final String address;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        children: [
          InkWell(
            key: const Key('client_post_project_change_location_button'),
            onTap: onChangeTap,
            child: Text(
              context.tr('projects.client.location_change'),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.photos,
    required this.onAddTap,
    required this.onRemoveTap,
  });

  final List<String> photos;
  final VoidCallback onAddTap;
  final ValueChanged<int> onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Photos thumbnails
          for (var i = 0; i < photos.length; i++) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildPhotoThumbnail(photos[i]),
                  PositionedDirectional(
                    top: -4,
                    end: -4,
                    child: InkWell(
                      onTap: () => onRemoveTap(i),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Add (+) photo tile
          InkWell(
            key: const Key('client_post_project_add_photo_button'),
            onTap: onAddTap,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.neutralLight,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.lg),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(String path) {
    final file = File(path);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        child: Image.file(
          file,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const AppPhotoTile(size: 72),
        ),
      );
    }
    return const AppPhotoTile(size: 72);
  }
}
