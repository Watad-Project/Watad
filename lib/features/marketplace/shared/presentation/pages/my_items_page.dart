import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_filter_chips.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/marketplace_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_item.dart';
import 'package:watad/features/marketplace/shared/domain/entities/my_items_filter.dart';
import 'package:watad/features/marketplace/shared/presentation/bloc/my_items_bloc.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/my_item_card.dart';

/// «منتجاتي» (`/marketplace/my-items`): displays the signed-in seller's
/// marketplace listings with status filter chips, hide/show toggle,
/// soft-delete, and admin removal reason for removed listings.
class MyItemsPage extends StatelessWidget {
  const MyItemsPage({super.key});

  static String _filterKey(MyItemsFilter filter) => switch (filter) {
    MyItemsFilter.all => 'marketplace.filter_all',
    MyItemsFilter.live => 'marketplace.filter_live',
    MyItemsFilter.hidden => 'marketplace.filter_hidden',
    MyItemsFilter.removed => 'marketplace.filter_removed',
    MyItemsFilter.outOfStock => 'marketplace.filter_out_of_stock',
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MyItemsBloc>();
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('marketplace.my_items_title'),
        onBack: () => context.pop(),
      ),
      bottomNavigationBar: AppActionBar(
        primary: AppButton(
          key: const Key('my_items_add_button'),
          label: context.tr('marketplace.my_items_add'),
          icon: Icons.add,
          onPressed: () async {
            await context.pushNamed(MarketplaceRoutes.newMyItemName);
            bloc.add(const MyItemsFetched());
          },
        ),
      ),
      body: BlocConsumer<MyItemsBloc, MyItemsState>(
        listenWhen: (previous, current) =>
            previous.actionFailure != current.actionFailure ||
            previous.actionDoneKey != current.actionDoneKey,
        listener: (context, state) {
          if (state.actionFailure case final failure?) {
            context.showErrorSnackBar(context.tr(failure.messageKey));
          } else if (state.actionDoneKey case final key?) {
            context.showSuccessSnackBar(context.tr(key));
          }
        },
        builder: (context, state) => RefreshIndicator(
          onRefresh: () async => bloc.add(const MyItemsFetched()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            children: [
              AppFilterChips(
                key: const Key('my_items_filter_chips'),
                isWrapped: true,
                labels: [
                  for (final filter in MyItemsFilter.values)
                    context.tr(_filterKey(filter)),
                ],
                selectedIndex: state.filter.index,
                onSelected: (index) =>
                    bloc.add(MyItemsFilterChanged(MyItemsFilter.values[index])),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._body(context, bloc, state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    MyItemsBloc bloc,
    MyItemsState state,
  ) {
    if (state.items.isEmpty) {
      return [
        switch (state.status) {
          MyItemsStatus.failure => AppErrorView(
            message: context.tr(state.failure!.messageKey),
            onRetry: () => bloc.add(const MyItemsFetched()),
          ),
          MyItemsStatus.success => AppEmptyView(
            message: context.tr('marketplace.my_items_empty'),
            icon: Icons.inventory_2_outlined,
          ),
          _ => const Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.xl),
            child: AppLoadingIndicator(),
          ),
        },
      ];
    }

    final visible = state.visibleItems;
    if (visible.isEmpty) {
      return [
        AppEmptyView(
          message: context.tr('marketplace.my_items_empty_filter'),
          icon: Icons.inventory_2_outlined,
        ),
      ];
    }

    return [
      for (var i = 0; i < visible.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.sm),
        MyItemCard(
          key: ValueKey(visible[i].id),
          item: visible[i],
          isBusy: state.busyItemId == visible[i].id,
          onTap: () => _openEdit(context, bloc, visible[i]),
          onEdit: visible[i].isRemoved
              ? null
              : () => _openEdit(context, bloc, visible[i]),
          onToggleVisibility: visible[i].isRemoved
              ? null
              : () => bloc.add(
                  MyItemVisibilityToggled(
                    itemId: visible[i].id,
                    isActive: !visible[i].isActive,
                  ),
                ),
          onDelete: visible[i].isRemoved
              ? null
              : () => _confirmDelete(context, bloc, visible[i]),
        ),
      ],
    ];
  }

  Future<void> _openEdit(
    BuildContext context,
    MyItemsBloc bloc,
    MarketplaceItem item,
  ) async {
    await context.pushNamed(
      MarketplaceRoutes.editMyItemName,
      pathParameters: {'itemId': item.id},
    );
    bloc.add(const MyItemsFetched());
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MyItemsBloc bloc,
    MarketplaceItem item,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('marketplace.my_items_delete_title'),
      message: context.tr('marketplace.my_items_delete_message'),
      confirmLabel: context.tr('common.delete'),
    );
    if (confirmed != null) {
      bloc.add(MyItemDeleted(item.id));
    }
  }
}
