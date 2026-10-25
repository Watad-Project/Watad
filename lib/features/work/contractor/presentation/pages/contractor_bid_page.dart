import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_bid_bloc.dart';

class ContractorBidPage extends StatefulWidget {
  const ContractorBidPage({required this.projectId, super.key});

  final String projectId;

  @override
  State<ContractorBidPage> createState() => _ContractorBidPageState();
}

class _ContractorBidPageState extends State<ContractorBidPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _didPrefill = false;

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(ContractorBidReady state) {
    if (_didPrefill) return;
    _didPrefill = true;
    final details = state.details;
    if (!details.hasPendingOffer) return;

    if (details.existingOfferAmount case final offerAmount?) {
      _amountController.text = '${offerAmount.toJson()}';
    }
    if (details.existingOfferMessage case final offerMessage?) {
      _messageController.text = offerMessage;
    }
  }

  void _popOrGoBack(BuildContext context, {bool result = false}) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.goNamed(ContractorWorkRoutes.workName);
    }
  }

  void _onSubmit(BuildContext context) {
    context.read<ContractorBidBloc>().add(
      ContractorBidSubmitted(
        amountText: _amountController.text,
        message: _messageController.text,
      ),
    );
  }

  Future<void> _onWithdraw(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('work.contractor.withdraw_confirm_title'),
      message: context.tr('work.contractor.withdraw_confirm_message'),
      confirmLabel: context.tr('work.contractor.withdraw_confirm_action'),
    );
    if (confirmed != null && context.mounted) {
      context.read<ContractorBidBloc>().add(const ContractorBidWithdrawn());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContractorBidBloc, ContractorBidState>(
      listener: (context, state) {
        if (state is! ContractorBidReady) return;
        _prefillIfNeeded(state);

        if (state.completedMessageKey case final messageKey?) {
          context.showSuccessSnackBar(context.tr(messageKey));
          _popOrGoBack(context, result: true);
          return;
        }

        if (state.actionFailure case final failure?) {
          context.showErrorSnackBar(
            context.tr(failure.messageKey),
            onRetry: failure is NetworkFailure
                ? () => _onSubmit(context)
                : null,
          );
        }
      },
      builder: (context, state) {
        if (state is ContractorBidReady) {
          _prefillIfNeeded(state);
        }

        final bottomBar = switch (state) {
          ContractorBidReady(:final details) when details.project != null =>
            details.hasPendingOffer
                ? AppActionBar(
                    primary: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: context.tr(
                              'work.contractor.save_offer_button',
                            ),
                            isLoading: state.isSubmitting,
                            onPressed:
                                details.isVerified && !state.isWithdrawing
                                ? () => _onSubmit(context)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            label: context.tr(
                              'work.contractor.withdraw_offer_button',
                            ),
                            variant: AppButtonVariant.secondary,
                            isLoading: state.isWithdrawing,
                            onPressed: !state.isSubmitting
                                ? () => _onWithdraw(context)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  )
                : AppActionBar(
                    primary: AppButton(
                      label: context.tr('work.contractor.send_offer_button'),
                      isLoading: state.isSubmitting,
                      onPressed: details.isVerified
                          ? () => _onSubmit(context)
                          : null,
                    ),
                  ),
          _ => null,
        };

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppTopBar(
            title: context.tr('work.contractor.bid_top_bar_title'),
            onBack: () => _popOrGoBack(context),
          ),
          bottomNavigationBar: bottomBar,
          body: SafeArea(
            child: switch (state) {
              ContractorBidInitial() ||
              ContractorBidLoadInProgress() => const AppLoadingIndicator(),
              ContractorBidLoadFailure(:final failure) => AppErrorView(
                message: context.tr(failure.messageKey),
                onRetry: () => context.read<ContractorBidBloc>().add(
                  ContractorBidStarted(widget.projectId),
                ),
              ),
              ContractorBidReady(:final details) when details.project == null =>
                _ProjectUnavailableView(onBack: () => _popOrGoBack(context)),
              ContractorBidReady(:final details) => _BidFormContent(
                project: details.project!,
                isVerified: details.isVerified,
                isBusy: state.isSubmitting || state.isWithdrawing,
                amountController: _amountController,
                messageController: _messageController,
                amountErrorKey: state.amountErrorKey,
                messageErrorKey: state.messageErrorKey,
              ),
            },
          ),
        );
      },
    );
  }
}

class _ProjectUnavailableView extends StatelessWidget {
  const _ProjectUnavailableView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppEmptyView(
              message: context.tr('work.contractor.project_no_longer_open'),
              icon: Icons.work_off_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: context.tr('work.contractor.back_to_opportunities'),
              variant: AppButtonVariant.secondary,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _BidFormContent extends StatelessWidget {
  const _BidFormContent({
    required this.project,
    required this.isVerified,
    required this.isBusy,
    required this.amountController,
    required this.messageController,
    this.amountErrorKey,
    this.messageErrorKey,
  });

  final ContractorOpenProject project;
  final bool isVerified;
  final bool isBusy;
  final TextEditingController amountController;
  final TextEditingController messageController;
  final String? amountErrorKey;
  final String? messageErrorKey;

  @override
  Widget build(BuildContext context) {
    final currency = context.tr('work.contractor.currency');
    final projectBudget = project.budget;
    final summaryMeta = projectBudget != null
        ? context.tr(
            'work.contractor.project_summary_meta',
            namedArgs: {
              'city': project.city,
              'budget': '${projectBudget.toJson()}',
              'currency': currency,
            },
          )
        : context.tr(
            'work.contractor.project_summary_meta_no_budget',
            namedArgs: {'city': project.city},
          );

    final district = project.district?.trim();
    final locationText = district != null && district.isNotEmpty
        ? context.tr(
            'work.contractor.location_with_district',
            namedArgs: {'city': project.city, 'district': district},
          )
        : project.city;

    final imageUrl = project.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 180,
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.primarySoft,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.home_work_rounded,
                                    size: 56,
                                    color: AppColors.primary,
                                  ),
                                ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppRadius.lg),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.home_work_rounded,
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.title, style: AppTextStyles.h2),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          AppIconTag(
                            label: context.tr(
                              'work.contractor.verified_ownership_tag',
                            ),
                            icon: Icons.check,
                            tone: AppTone.success,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              summaryMeta,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.tr('work.contractor.project_address_title'),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              locationText,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (project.description.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          context.tr(
                            'work.contractor.project_requirements_title',
                          ),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          project.description,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppIconTag(
                    label: context.tr('work.contractor.unverified_warning'),
                    icon: Icons.priority_high,
                    tone: AppTone.attention,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: context.tr(
                      'work.contractor.check_verification_status',
                    ),
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.pushNamed(KycRoutes.statusName),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: context.tr('work.contractor.bid_amount_label'),
            isRequired: true,
            controller: amountController,
            hint: context.tr('work.contractor.bid_amount_hint'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            isMonospace: true,
            enabled: isVerified && !isBusy,
            errorText: amountErrorKey != null
                ? context.tr(amountErrorKey!)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: context.tr('work.contractor.bid_message_label'),
            isRequired: true,
            controller: messageController,
            hint: context.tr('work.contractor.bid_message_hint'),
            minLines: 4,
            maxLines: 6,
            enabled: isVerified && !isBusy,
            errorText: messageErrorKey != null
                ? context.tr(messageErrorKey!)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('work.contractor.bid_pending_note'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/display/app_icon_tag.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_bid_bloc.dart';

class ContractorBidPage extends StatefulWidget {
  const ContractorBidPage({required this.projectId, super.key});

  final String projectId;

  @override
  State<ContractorBidPage> createState() => _ContractorBidPageState();
}

class _ContractorBidPageState extends State<ContractorBidPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _didPrefill = false;

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(ContractorBidReady state) {
    if (_didPrefill) return;
    _didPrefill = true;
    final details = state.details;
    if (!details.hasPendingOffer) return;

    if (details.existingOfferAmount case final offerAmount?) {
      _amountController.text = '${offerAmount.toJson()}';
    }
    if (details.existingOfferMessage case final offerMessage?) {
      _messageController.text = offerMessage;
    }
  }

  void _popOrGoBack(BuildContext context, {bool result = false}) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.goNamed(ContractorWorkRoutes.workName);
    }
  }

  void _onSubmit(BuildContext context) {
    context.read<ContractorBidBloc>().add(
      ContractorBidSubmitted(
        amountText: _amountController.text,
        message: _messageController.text,
      ),
    );
  }

  Future<void> _onWithdraw(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('work.contractor.withdraw_confirm_title'),
      message: context.tr('work.contractor.withdraw_confirm_message'),
      confirmLabel: context.tr('work.contractor.withdraw_confirm_action'),
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<ContractorBidBloc>().add(const ContractorBidWithdrawn());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContractorBidBloc, ContractorBidState>(
      listener: (context, state) {
        if (state is! ContractorBidReady) return;
        _prefillIfNeeded(state);

        if (state.completedMessageKey case final messageKey?) {
          context.showSuccessSnackBar(context.tr(messageKey));
          _popOrGoBack(context, result: true);
          return;
        }

        if (state.actionFailure case final failure?) {
          context.showErrorSnackBar(
            context.tr(failure.messageKey),
            onRetry: failure is NetworkFailure
                ? () => _onSubmit(context)
                : null,
          );
        }
      },
      builder: (context, state) {
        if (state is ContractorBidReady) {
          _prefillIfNeeded(state);
        }

        final bottomBar = switch (state) {
          ContractorBidReady(:final details) when details.project != null =>
            details.hasPendingOffer
                ? AppActionBar(
                    primary: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: context.tr(
                              'work.contractor.save_offer_button',
                            ),
                            isLoading: state.isSubmitting,
                            onPressed:
                                details.isVerified && !state.isWithdrawing
                                ? () => _onSubmit(context)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            label: context.tr(
                              'work.contractor.withdraw_offer_button',
                            ),
                            variant: AppButtonVariant.secondary,
                            isLoading: state.isWithdrawing,
                            onPressed: !state.isSubmitting
                                ? () => _onWithdraw(context)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  )
                : AppActionBar(
                    primary: AppButton(
                      label: context.tr('work.contractor.send_offer_button'),
                      isLoading: state.isSubmitting,
                      onPressed: details.isVerified
                          ? () => _onSubmit(context)
                          : null,
                    ),
                  ),
          _ => null,
        };

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppTopBar(
            title: context.tr('work.contractor.bid_top_bar_title'),
            onBack: () => _popOrGoBack(context),
          ),
          bottomNavigationBar: bottomBar,
          body: SafeArea(
            child: switch (state) {
              ContractorBidInitial() ||
              ContractorBidLoadInProgress() => const AppLoadingIndicator(),
              ContractorBidLoadFailure(:final failure) => AppErrorView(
                message: context.tr(failure.messageKey),
                onRetry: () => context.read<ContractorBidBloc>().add(
                  ContractorBidStarted(widget.projectId),
                ),
              ),
              ContractorBidReady(:final details) when details.project == null =>
                _ProjectUnavailableView(onBack: () => _popOrGoBack(context)),
              ContractorBidReady(:final details) => _BidFormContent(
                project: details.project!,
                isVerified: details.isVerified,
                isBusy: state.isSubmitting || state.isWithdrawing,
                amountController: _amountController,
                messageController: _messageController,
                amountErrorKey: state.amountErrorKey,
                messageErrorKey: state.messageErrorKey,
              ),
            },
          ),
        );
      },
    );
  }
}

class _ProjectUnavailableView extends StatelessWidget {
  const _ProjectUnavailableView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppEmptyView(
              message: context.tr('work.contractor.project_no_longer_open'),
              icon: Icons.work_off_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: context.tr('work.contractor.back_to_opportunities'),
              variant: AppButtonVariant.secondary,
              onPressed: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _BidFormContent extends StatelessWidget {
  const _BidFormContent({
    required this.project,
    required this.isVerified,
    required this.isBusy,
    required this.amountController,
    required this.messageController,
    this.amountErrorKey,
    this.messageErrorKey,
  });

  final ContractorOpenProject project;
  final bool isVerified;
  final bool isBusy;
  final TextEditingController amountController;
  final TextEditingController messageController;
  final String? amountErrorKey;
  final String? messageErrorKey;

  @override
  Widget build(BuildContext context) {
    final currency = context.tr('work.contractor.currency');
    final projectBudget = project.budget;
    final summaryMeta = projectBudget != null
        ? context.tr(
            'work.contractor.project_summary_meta',
            namedArgs: {
              'city': project.city,
              'budget': '${projectBudget.toJson()}',
              'currency': currency,
            },
          )
        : context.tr(
            'work.contractor.project_summary_meta_no_budget',
            namedArgs: {'city': project.city},
          );

    final district = project.district?.trim();
    final locationText = district != null && district.isNotEmpty
        ? context.tr(
            'work.contractor.location_with_district',
            namedArgs: {'city': project.city, 'district': district},
          )
        : project.city;

    final imageUrl = project.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 180,
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppColors.primarySoft,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.home_work_rounded,
                                    size: 56,
                                    color: AppColors.primary,
                                  ),
                                ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppRadius.lg),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.home_work_rounded,
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.title, style: AppTextStyles.h2),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          AppIconTag(
                            label: context.tr(
                              'work.contractor.verified_ownership_tag',
                            ),
                            icon: Icons.check,
                            tone: AppTone.success,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              summaryMeta,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.tr('work.contractor.project_address_title'),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              locationText,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (project.description.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          context.tr(
                            'work.contractor.project_requirements_title',
                          ),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          project.description,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppIconTag(
                    label: context.tr('work.contractor.unverified_warning'),
                    icon: Icons.priority_high,
                    tone: AppTone.attention,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: context.tr(
                      'work.contractor.check_verification_status',
                    ),
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.pushNamed(KycRoutes.statusName),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: context.tr('work.contractor.bid_amount_label'),
            isRequired: true,
            controller: amountController,
            hint: context.tr('work.contractor.bid_amount_hint'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            isMonospace: true,
            enabled: isVerified && !isBusy,
            errorText: amountErrorKey != null
                ? context.tr(amountErrorKey!)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: context.tr('work.contractor.bid_message_label'),
            isRequired: true,
            controller: messageController,
            hint: context.tr('work.contractor.bid_message_hint'),
            minLines: 4,
            maxLines: 6,
            enabled: isVerified && !isBusy,
            errorText: messageErrorKey != null
                ? context.tr(messageErrorKey!)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('work.contractor.bid_pending_note'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
