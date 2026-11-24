import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_address_card.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/location_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_addresses_bloc.dart';

/// «عناويني»: my saved addresses, from the account tab. «إضافة عنوان» opens
/// the map picker and saves what it picks; an address can be deleted,
/// except the site of a project that is still going. Editing waits: a saved
/// address keeps no map position to start from.
class LocationAddressesPage extends StatelessWidget {
  const LocationAddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LocationAddressesBloc>();
    void reload() => bloc.add(const LocationAddressesFetched());
    return BlocListener<LocationAddressesBloc, LocationAddressesState>(
      listenWhen: (previous, current) =>
          (current.deleted && !previous.deleted) ||
          (current.actionFailure != null &&
              previous.actionFailure != current.actionFailure),
      listener: (context, state) {
        if (state.actionFailure case final failure?) {
          context.showErrorSnackBar(context.tr(failure.messageKey));
        } else {
          context.showSuccessSnackBar(context.tr('location.addresses_deleted'));
        }
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: context.tr('location.addresses_title'),
          onBack: () => context.pop(),
        ),
        body: BlocBuilder<LocationAddressesBloc, LocationAddressesState>(
          builder: (context, state) {
            final addresses = state.addresses;
            if (addresses == null) {
              return switch (state.failure) {
                final failure? => AppErrorView(
                  message: context.tr(failure.messageKey),
                  onRetry: reload,
                ),
                null => const AppLoadingIndicator(),
              };
            }
            if (addresses.isEmpty) {
              return AppEmptyView(
                message: context.tr('location.addresses_empty'),
                icon: Icons.location_off_outlined,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => reload(),
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                itemCount: addresses.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _AddressItem(
                  key: ValueKey(addresses[index].id),
                  address: addresses[index],
                  isDeleting: state.deletingId == addresses[index].id,
                  onDelete: () => _confirmDelete(context, addresses[index]),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: AppActionBar(
          primary: AppButton(
            key: const Key('location_addresses_add'),
            label: context.tr('location.addresses_add'),
            icon: Icons.add_location_alt_outlined,
            onPressed: () async {
              // Always saved, so the new address is in the list after.
              await context.pushNamed<String>(
                LocationRoutes.locationName,
                queryParameters: {'save': 'required'},
              );
              reload();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LocationAddress address,
  ) async {
    final bloc = context.read<LocationAddressesBloc>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('location.addresses_delete_title'),
      message: context.tr('location.addresses_delete_message'),
      confirmLabel: context.tr('location.addresses_delete'),
    );
    if (confirmed != null) bloc.add(LocationAddressDeleted(address));
  }
}

/// One address; the site of a project that is still going can't be
/// deleted, and says so.
class _AddressItem extends StatelessWidget {
  const _AddressItem({
    required this.address,
    required this.isDeleting,
    required this.onDelete,
    super.key,
  });

  final LocationAddress address;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = address.name.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppAddressCard(
          title: name.isEmpty ? context.tr('location.addresses_no_name') : name,
          address: address.formattedAddress,
          onEdit: null,
          onDelete: address.isActiveProjectSite || isDeleting ? null : onDelete,
        ),
        if (address.isActiveProjectSite)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
            child: Text(
              context.tr('location.addresses_project_site'),
              style: AppTextStyles.caption,
            ),
          ),
      ],
    );
  }
}
