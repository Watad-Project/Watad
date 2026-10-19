import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/inputs/app_radio_row.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/location_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

class _ClientSavedAddress {
  const _ClientSavedAddress({
    required this.id,
    required this.name,
    required this.formattedAddress,
  });

  final String id;
  final String name;
  final String formattedAddress;
}

/// Page for selecting a saved address or launching the map to pick a new one.
class ClientPostProjectAddressPage extends StatefulWidget {
  const ClientPostProjectAddressPage({super.key});

  @override
  State<ClientPostProjectAddressPage> createState() =>
      _ClientPostProjectAddressPageState();
}

class _ClientPostProjectAddressPageState
    extends State<ClientPostProjectAddressPage> {
  _ClientSavedAddress? _selectedAddress;
  bool _initialized = false;
  List<_ClientSavedAddress> _addresses = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _addresses = [
        _ClientSavedAddress(
          id: 'addr_1',
          name: context.tr('projects.client.default_location_deed'),
          formattedAddress: context.tr('projects.client.default_location_deed'),
        ),
        _ClientSavedAddress(
          id: 'addr_2',
          name: context.tr('projects.client.default_location_repairs'),
          formattedAddress: context.tr(
            'projects.client.default_location_repairs',
          ),
        ),
      ];
      _selectedAddress = _addresses.first;
    }
  }

  Future<void> _onPickNewLocation() async {
    final result = await context.pushNamed<dynamic>(
      LocationRoutes.locationName,
    );
    if (!mounted || result == null) return;

    final addressStr = result.toString();
    if (addressStr.trim().isNotEmpty) {
      context.pop(addressStr);
    }
  }

  void _onConfirmSelected() {
    if (_selectedAddress != null) {
      context.pop(_selectedAddress!.formattedAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: context.tr('projects.client.address_title'),
        onBack: () => context.pop(),
      ),
      bottomNavigationBar: AppActionBar(
        primary: AppButton(
          key: const Key('client_post_project_use_address_button'),
          label: context.tr('projects.client.address_use_selected'),
          onPressed: _selectedAddress != null ? _onConfirmSelected : null,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtitle
            Text(
              context.tr('projects.client.address_subtitle'),
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Pick new location action card
            Material(
              color: AppColors.surfaceMuted,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
                side: BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                key: const Key('client_post_project_new_location_button'),
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.lg),
                ),
                onTap: _onPickNewLocation,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_location_alt_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('projects.client.address_new_on_map'),
                              style: AppTextStyles.h2.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              context.tr(
                                'projects.client.address_new_on_map_desc',
                              ),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Saved addresses section title
            Text(
              context.tr('projects.client.address_saved_title'),
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Empty state or list
            if (_addresses.isEmpty) ...[
              AppStatusCard(
                tone: AppTone.neutral,
                title: context.tr('projects.client.address_empty_title'),
                subtitle: context.tr('projects.client.address_empty_desc'),
              ),
            ] else ...[
              ..._addresses.map((address) {
                final isSelected = _selectedAddress?.id == address.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: AppRadioRow(
                    key: ValueKey('client_address_radio_${address.id}'),
                    title: address.name,
                    subtitle: address.formattedAddress,
                    selected: isSelected,
                    onTap: () {
                      setState(() => _selectedAddress = address);
                    },
                  ),
                );
              }),
            ],
            const SizedBox(height: AppSpacing.md),

            // Deed match informative notice
            AppStatusCard(
              tone: AppTone.attention,
              title: context.tr('projects.client.address_deed_hint'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
