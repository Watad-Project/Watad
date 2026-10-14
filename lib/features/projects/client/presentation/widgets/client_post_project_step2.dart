import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/display/app_photo_tile.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_dropdown.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_step_progress.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
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
  });

  final ClientPostProjectState state;
  final ValueChanged<ClientProjectType> onTypeChanged;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<Money?> onMinBudgetChanged;
  final ValueChanged<Money?> onMaxBudgetChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onPhotoAdded;
  final ValueChanged<int> onPhotoRemoved;

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

    // Provide default location if not set yet
    if (widget.state.locationAddress == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final defaultLoc = widget.state.requiresDeed
            ? context.tr('projects.client.default_location_deed')
            : context.tr('projects.client.default_location_repairs');
        widget.onLocationChanged(defaultLoc);
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDeedRequired = state.requiresDeed;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step progress indicator (Step 2 of 4 or Step 2 of 3)
          AppStepProgress(current: 2, total: state.totalSteps),

          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('projects.client.details_title'),
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Project type dropdown (changeable from here)
          AppDropdown<ClientProjectType>(
            label: context.tr('projects.client.project_type_label'),
            value: state.projectType,
            options: [
              AppDropdownOption<ClientProjectType>(
                value: ClientProjectType.newHouse,
                title: context.tr(ClientProjectType.newHouse.titleKey),
                subtitle: context.tr(ClientProjectType.newHouse.hintKey),
                subtitleTone: AppTone.attention,
                tag: context.tr(ClientProjectType.newHouse.tagKey),
                tagTone: AppTone.attention,
              ),
              AppDropdownOption<ClientProjectType>(
                value: ClientProjectType.renovation,
                title: context.tr(ClientProjectType.renovation.titleKey),
                subtitle: context.tr(ClientProjectType.renovation.hintKey),
                subtitleTone: AppTone.attention,
                tag: context.tr(ClientProjectType.renovation.tagKey),
                tagTone: AppTone.attention,
              ),
              AppDropdownOption<ClientProjectType>(
                value: ClientProjectType.repairs,
                title: context.tr(ClientProjectType.repairs.titleKey),
                subtitle: context.tr(ClientProjectType.repairs.hintKey),
                subtitleTone: AppTone.success,
                tag: context.tr(ClientProjectType.repairs.tagKey),
                tagTone: AppTone.success,
              ),
            ],
            onChanged: (newType) {
              widget.onTypeChanged(newType);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Scope of work
          AppTextField(
            label: context.tr('projects.client.scope_of_work_label'),
            controller: _scopeController,
            hint: isDeedRequired
                ? context.tr('projects.client.scope_of_work_hint_deed')
                : context.tr('projects.client.scope_of_work_hint_repairs'),
            minLines: 3,
            maxLines: 5,
            onChanged: widget.onScopeChanged,
          ),
          const SizedBox(height: AppSpacing.md),

          // Budget range (Min and Max side by side)
          AppFieldLabel(label: context.tr('projects.client.budget_label')),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _minBudgetController,
                  hint: context.tr('projects.client.budget_min_hint'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) {
                    final parsed = _parseNumber(val);
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
                  hint: context.tr('projects.client.budget_max_hint'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) {
                    final parsed = _parseNumber(val);
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

          // Project Location
          AppFieldLabel(label: context.tr('projects.client.location_label')),
          const SizedBox(height: AppSpacing.xs),
          _LocationCard(
            address:
                state.locationAddress ??
                (isDeedRequired
                    ? context.tr('projects.client.default_location_deed')
                    : context.tr('projects.client.default_location_repairs')),
            onChangeTap: () async {
              final result = await context.pushNamed<dynamic>(
                ClientProjectsRoutes.postProjectAddressName,
              );
              if (result is String && result.trim().isNotEmpty) {
                widget.onLocationChanged(result);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Variant A: Photos row (if deed required)
          if (isDeedRequired) ...[
            _PhotosSection(
              photos: state.photos,
              onAddTap: () {
                widget.onPhotoAdded('photo');
              },
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
          // Action button on the leading edge (in RTL: left)
          InkWell(
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
          // Address text with location pin
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
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
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
                      const AppPhotoTile(size: 72, placeholderLabel: 'photo'),
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
                      Icons.add,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
