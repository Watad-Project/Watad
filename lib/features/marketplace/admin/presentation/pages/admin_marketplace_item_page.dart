import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/router/routes/admin_users_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/admin/domain/entities/admin_marketplace_item.dart';
import 'package:watad/features/marketplace/admin/presentation/bloc/admin_marketplace_item_bloc.dart';
import 'package:watad/features/marketplace/admin/presentation/widgets/admin_marketplace_item_overview.dart';
import 'package:watad/features/marketplace/admin/presentation/widgets/admin_marketplace_labels.dart';
import 'package:watad/features/marketplace/admin/presentation/widgets/admin_marketplace_skeleton.dart';

/// One listing's page: everything about it, its seller, and «إزالة المنتج»;
/// a removed listing shows when, by whom and why instead.
class AdminMarketplaceItemPage extends StatelessWidget {
  const AdminMarketplaceItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('marketplace.item_title'),
        onBack: () => context.pop(),
      ),
      body: BlocConsumer<AdminMarketplaceItemBloc, AdminMarketplaceItemState>(
        listenWhen: (previous, current) =>
            current.message != null && previous.message != current.message,
        listener: (context, state) {
          final message = state.message!;
          if (message.isError) {
            context.showErrorSnackBar(context.tr(message.key));
          } else {
            context.showSuccessSnackBar(context.tr(message.key));
          }
        },
        // Loading, the listing and errors fade into each other.
        builder: (context, state) => AnimatedSwitcher(
          duration: AppMotion.enter,
          reverseDuration: AppMotion.exit,
          switchInCurve: AppMotion.enterCurve,
          switchOutCurve: AppMotion.exitCurve,
          child: _body(context, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AdminMarketplaceItemState state) {
    final bloc = context.read<AdminMarketplaceItemBloc>();
    final item = state.item;
    if (item == null) {
      return switch (state.failure) {
        NotFoundFailure() => AppEmptyView(
          key: const ValueKey('not_found'),
          message: context.tr('marketplace.error_not_found'),
          icon: Icons.search_off_rounded,
        ),
        final failure? => AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(failure.messageKey),
          onRetry: () {
            if (state.itemId case final id?) {
              bloc.add(AdminMarketplaceItemFetched(id));
            }
          },
        ),
        // A list, so the skeleton never runs off a small screen.
        null => ListView(
          key: const ValueKey('loading'),
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          children: const [AdminMarketplaceSkeleton()],
        ),
      };
    }
    return ListView(
      key: const ValueKey('item'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        AdminMarketplaceItemOverview(
          item: item,
          onSellerTap: () => context.pushNamed(
            AdminUsersRoutes.userDetailsName,
            pathParameters: {'userId': item.sellerId},
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (item.isRemoved)
          AppStatusCard(
            tone: AppTone.danger,
            title: context.tr('marketplace.status_removed'),
            subtitle: _removedSince(context, item),
            reasonTitle: context.tr('common.reason'),
            reasonText: item.removalReason,
          )
        else
          AppButton(
            label: context.tr('marketplace.remove'),
            variant: AppButtonVariant.dark,
            isLoading: state.isBusy,
            onPressed: state.isBusy ? null : () => _remove(context, bloc),
          ),
      ],
    );
  }

  Future<void> _remove(
    BuildContext context,
    AdminMarketplaceItemBloc bloc,
  ) async {
    final reason = await AppConfirmDialog.show(
      context,
      title: context.tr('marketplace.remove_title'),
      message: context.tr('marketplace.remove_message'),
      confirmLabel: context.tr('marketplace.remove'),
      reasonLabel: context.tr('common.reason'),
    );
    if (reason != null) bloc.add(AdminMarketplaceItemRemoved(reason));
  }

  /// «منذ ٢٢ أكتوبر ٢٠٢٦ ٤:٠٥ م، بواسطة عمر».
  static String? _removedSince(
    BuildContext context,
    AdminMarketplaceItem item,
  ) {
    final since = item.removedAt;
    if (since == null) return null;
    final date = AdminMarketplaceLabels.date(context, since);
    final by = item.removedByName;
    return by == null
        ? context.tr('marketplace.removed_since', args: [date])
        : context.tr('marketplace.removed_since_by', args: [date, by]);
  }
}
