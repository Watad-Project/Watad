import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/components/display/app_photo_tile.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_dropdown.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/inputs/app_upload_zone.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/marketplace_category.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_item_form_bloc.dart';

/// Shared scaffold and form body for adding (`/marketplace/my-items/new`) and
/// editing (`/marketplace/my-items/:itemId/edit`) a seller listing.
class MyItemFormView extends StatefulWidget {
  const MyItemFormView({
    required this.titleKey,
    required this.submitLabelKey,
    this.onPickPhoto,
    super.key,
  });

  final String titleKey;
  final String submitLabelKey;

  /// Optional photo picker override for testing; defaults to opening the
  /// device gallery via `ImagePicker`.
  final Future<String?> Function()? onPickPhoto;

  @override
  State<MyItemFormView> createState() => _MyItemFormViewState();
}

class _MyItemFormViewState extends State<MyItemFormView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _seededFromState = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncControllersIfNeeded(MyItemFormState state) {
    if (_seededFromState || state.status != MyItemFormStatus.ready) return;
    _seededFromState = true;
    _nameController.text = state.name;
    _priceController.text = state.priceText;
    _stockController.text = state.stockText;
    _descriptionController.text = state.description;
  }

  Future<void> _pickPhoto(MyItemFormBloc bloc) async {
    final picker = widget.onPickPhoto;
    if (picker != null) {
      final path = await picker();
      if (path != null && mounted) {
        bloc.add(MyItemFormPhotoAdded(path));
      }
      return;
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      bloc.add(MyItemFormPhotoAdded(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyItemFormBloc>();
    return BlocConsumer<MyItemFormBloc, MyItemFormState>(
      listenWhen: (previous, current) =>
          previous.submitFailure != current.submitFailure ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.submitFailure case final failure?) {
          context.showErrorSnackBar(context.tr(failure.messageKey));
        } else if (state.status == MyItemFormStatus.saved) {
          context.showSuccessSnackBar(
            context.tr(
              state.isEditing
                  ? 'marketplace.my_items_updated_done'
                  : 'marketplace.my_items_created_done',
            ),
          );
          if (context.canPop()) {
            context.pop(true);
          }
        }
      },
      builder: (context, state) {
        _syncControllersIfNeeded(state);
        final canSubmit =
            state.status == MyItemFormStatus.ready ||
            state.status == MyItemFormStatus.submitting;
        return Scaffold(
          appBar: AppTopBar(
            title: context.tr(widget.titleKey),
            onBack: () => context.pop(),
          ),
          bottomNavigationBar: canSubmit && !state.isRemoved
              ? AppActionBar(
                  primary: AppButton(
                    key: const Key('my_item_form_submit'),
                    label: context.tr(widget.submitLabelKey),
                    isLoading: state.status == MyItemFormStatus.submitting,
                    onPressed: () => bloc.add(const MyItemFormSubmitted()),
                  ),
                )
              : null,
          body: switch (state.status) {
            MyItemFormStatus.initial ||
            MyItemFormStatus.loading => const AppLoadingIndicator(),
            MyItemFormStatus.failure => AppErrorView(
              message: context.tr(state.loadFailure!.messageKey),
              onRetry: () => bloc.add(MyItemFormStarted(itemId: state.itemId)),
            ),
            MyItemFormStatus.ready ||
            MyItemFormStatus.submitting ||
            MyItemFormStatus.saved => _buildForm(context, bloc, state),
          },
        );
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    MyItemFormBloc bloc,
    MyItemFormState state,
  ) {
    final editable =
        !state.isRemoved && state.status != MyItemFormStatus.submitting;
    return ListView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        if (state.isRemoved) ...[
          AppStatusCard(
            tone: AppTone.danger,
            title: context.tr('marketplace.status_removed'),
            subtitle: context.tr('marketplace.my_items_removed_readonly'),
            reasonTitle: context.tr('common.reason'),
            reasonText: state.removalReason,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppTextField(
          key: const Key('my_item_name_field'),
          controller: _nameController,
          label: context.tr('marketplace.my_items_name_label'),
          hint: context.tr('marketplace.my_items_name_hint'),
          isRequired: true,
          enabled: editable,
          errorText: state.nameErrorKey == null
              ? null
              : context.tr(state.nameErrorKey!),
          onChanged: (value) => bloc.add(MyItemFormNameChanged(value)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppDropdown<MarketplaceCategory>(
          key: const Key('my_item_category_dropdown'),
          floating: true,
          label: context.tr('marketplace.my_items_category_label'),
          hint: context.tr('marketplace.my_items_category_hint'),
          isRequired: true,
          value: state.category,
          errorText: state.categoryErrorKey == null
              ? null
              : context.tr(state.categoryErrorKey!),
          options: [
            for (final category in MarketplaceCategory.values)
              AppDropdownOption(
                value: category,
                title: context.tr('marketplace.categories.${category.value}'),
              ),
          ],
          onChanged: editable
              ? (category) => bloc.add(MyItemFormCategoryChanged(category))
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('my_item_price_field'),
          controller: _priceController,
          label: context.tr('marketplace.price'),
          hint: context.tr('marketplace.my_items_price_hint'),
          helperText: context.tr('marketplace.my_items_price_note'),
          isRequired: true,
          enabled: editable,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: state.priceErrorKey == null
              ? null
              : context.tr(state.priceErrorKey!),
          onChanged: (value) => bloc.add(MyItemFormPriceChanged(value)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('my_item_stock_field'),
          controller: _stockController,
          label: context.tr('marketplace.stock_label'),
          hint: context.tr('marketplace.my_items_stock_hint'),
          isRequired: true,
          enabled: editable,
          keyboardType: TextInputType.number,
          errorText: state.stockErrorKey == null
              ? null
              : context.tr(state.stockErrorKey!),
          onChanged: (value) => bloc.add(MyItemFormStockChanged(value)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('my_item_description_field'),
          controller: _descriptionController,
          label: context.tr('marketplace.description'),
          hint: context.tr('marketplace.my_items_description_hint'),
          enabled: editable,
          minLines: 3,
          maxLines: 5,
          errorText: state.descriptionErrorKey == null
              ? null
              : context.tr(state.descriptionErrorKey!),
          onChanged: (value) => bloc.add(MyItemFormDescriptionChanged(value)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppFieldLabel(
          label: context.tr(
            'marketplace.my_items_photos_label',
            args: [
              context.formatNumber(state.photos.length),
              context.formatNumber(MyItemFormState.maxPhotos),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('marketplace.my_items_photos_hint'),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.photos.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < state.photos.length; i++)
                Stack(
                  children: [
                    AppPhotoTile(
                      placeholderLabel: context.formatNumber(i + 1),
                      semanticLabel: state.photos[i],
                    ),
                    if (editable)
                      PositionedDirectional(
                        top: 0,
                        end: 0,
                        child: AppIconButton(
                          key: ValueKey('my_item_photo_remove_$i'),
                          icon: Icons.close,
                          tooltip: context.tr('common.delete'),
                          onPressed: () => bloc.add(MyItemFormPhotoRemoved(i)),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (editable && state.photos.length < MyItemFormState.maxPhotos)
          AppUploadZone(
            key: const Key('my_item_add_photo'),
            icon: Icons.add_photo_alternate_outlined,
            label: context.tr('marketplace.my_items_add_photo'),
            onTap: () => _pickPhoto(bloc),
          ),
      ],
    );
  }
}
