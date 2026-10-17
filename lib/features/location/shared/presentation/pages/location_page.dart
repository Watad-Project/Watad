import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_google_map.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/components/inputs/app_switch.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/location/shared/domain/entities/location_address.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_bloc.dart';

/// The shared map location picker page across client and contractor roles.
class LocationPage extends StatefulWidget {
  const LocationPage({
    super.key,
    this.initialAddress,
    this.showSaveToggle = true,
  });

  /// Optional initial address to display on the map and edit fields.
  final LocationAddress? initialAddress;

  /// Whether to display the "حفظ في عناويني" toggle.
  final bool showSaveToggle;

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late final TextEditingController _searchController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _streetController;
  late final TextEditingController _buildingController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAddress;
    _searchController = TextEditingController();
    _cityController = TextEditingController(text: initial?.city ?? '');
    _districtController = TextEditingController(text: initial?.district ?? '');
    _streetController = TextEditingController(text: initial?.street ?? '');
    _buildingController = TextEditingController(
      text: initial?.buildingNumber ?? '',
    );
    _postalCodeController = TextEditingController(
      text: initial?.postalCode ?? '',
    );
    _nameController = TextEditingController(text: initial?.name ?? '');

    context.read<LocationBloc>().add(
      LocationStarted(
        initialAddress: widget.initialAddress,
        showSaveToggle: widget.showSaveToggle,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _postalCodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _syncControllersWithState(LocationState state) {
    if (_cityController.text != state.address.city) {
      _cityController.text = state.address.city;
    }
    if (_districtController.text != state.address.district) {
      _districtController.text = state.address.district;
    }
    if (_streetController.text != state.address.street) {
      _streetController.text = state.address.street;
    }
    if (_buildingController.text != state.address.buildingNumber) {
      _buildingController.text = state.address.buildingNumber;
    }
    if (_postalCodeController.text != state.address.postalCode) {
      _postalCodeController.text = state.address.postalCode;
    }
    if (_nameController.text != state.address.name) {
      _nameController.text = state.address.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationBloc, LocationState>(
      listener: (context, state) {
        _syncControllersWithState(state);
        if (state.status == LocationStatus.success &&
            state.confirmedAddress != null) {
          context.pop(state.confirmedAddress!.formattedAddress);
        }
        if (state.status == LocationStatus.failure) {
          final messageKey = state.failure?.messageKey ?? state.errorMessage;
          if (messageKey != null) {
            context.showErrorSnackBar(context.tr(messageKey));
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppTopBar(
            title: context.tr('location.page_title'),
            onBack: () => context.pop(),
          ),
          bottomNavigationBar: AppActionBar(
            primary: AppButton(
              key: const Key('location_confirm_button'),
              label: context.tr('location.confirm_location'),
              onPressed: state.canConfirm
                  ? () {
                      context.read<LocationBloc>().add(
                        const LocationConfirmed(),
                      );
                    }
                  : null,
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Upper Half: Interactive / Mockup Map Area
                  Expanded(
                    flex: 5,
                    child: _MapMockupSection(
                      searchController: _searchController,
                      onSearchChanged: (q) {
                        context.read<LocationBloc>().add(
                          LocationSearchQueryChanged(q),
                        );
                      },
                      onSearchSubmitted: () {
                        context.read<LocationBloc>().add(
                          const LocationSearchSubmitted(),
                        );
                      },
                      onCurrentLocationTap: () {
                        context.read<LocationBloc>().add(
                          LocationCurrentPositionRequested(
                            city: context.tr('location.mock_current_city'),
                            district: context.tr(
                              'location.mock_current_district',
                            ),
                            street: context.tr('location.mock_current_street'),
                            buildingNumber: context.tr(
                              'location.mock_current_building',
                            ),
                            postalCode: context.tr(
                              'location.mock_current_postal_code',
                            ),
                          ),
                        );
                      },
                      onDragEnd: (lat, lng) {
                        context.read<LocationBloc>().add(
                          LocationCoordinatesChanged(
                            latitude: lat,
                            longitude: lng,
                          ),
                        );
                      },
                    ),
                  ),

                  // Lower Half: Address Form Bottom Panel
                  Expanded(
                    flex: 6,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xl),
                        ),
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header row: "العنوان" + "يُعبأ تلقائياً من الخريطة"
                            Row(
                              children: [
                                Text(
                                  context.tr('location.address_section_title'),
                                  style: AppTextStyles.h2,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  context.tr(
                                    'location.address_section_subtitle',
                                  ),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // City & District row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppFieldLabel(
                                        label: context.tr(
                                          'location.city_label',
                                        ),
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      AppTextField(
                                        key: const Key('location_city_input'),
                                        controller: _cityController,
                                        onChanged: (val) {
                                          context.read<LocationBloc>().add(
                                            LocationCityChanged(val),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppFieldLabel(
                                        label: context.tr(
                                          'location.district_label',
                                        ),
                                        isRequired: true,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      AppTextField(
                                        key: const Key(
                                          'location_district_input',
                                        ),
                                        controller: _districtController,
                                        onChanged: (val) {
                                          context.read<LocationBloc>().add(
                                            LocationDistrictChanged(val),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Street
                            AppFieldLabel(
                              label: context.tr('location.street_label'),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppTextField(
                              key: const Key('location_street_input'),
                              controller: _streetController,
                              onChanged: (val) {
                                context.read<LocationBloc>().add(
                                  LocationStreetChanged(val),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Building number & Postal code
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppFieldLabel(
                                        label: context.tr(
                                          'location.building_number_label',
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      AppTextField(
                                        key: const Key(
                                          'location_building_number_input',
                                        ),
                                        controller: _buildingController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          context.read<LocationBloc>().add(
                                            LocationBuildingNumberChanged(val),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppFieldLabel(
                                        label: context.tr(
                                          'location.postal_code_label',
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      AppTextField(
                                        key: const Key(
                                          'location_postal_code_input',
                                        ),
                                        controller: _postalCodeController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          context.read<LocationBloc>().add(
                                            LocationPostalCodeChanged(val),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Address label name
                            AppFieldLabel(
                              label: context.tr('location.address_name_label'),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppTextField(
                              key: const Key('location_name_input'),
                              controller: _nameController,
                              hint: context.tr('location.address_name_hint'),
                              onChanged: (val) {
                                context.read<LocationBloc>().add(
                                  LocationNameChanged(val),
                                );
                              },
                            ),

                            // Save to my addresses toggle
                            if (state.showSaveToggle) ...[
                              const SizedBox(height: AppSpacing.md),
                              AppSwitch(
                                key: const Key('location_save_switch'),
                                value: state.shouldSave,
                                label: context.tr(
                                  'location.save_to_my_addresses',
                                ),
                                onChanged: (val) {
                                  context.read<LocationBloc>().add(
                                    LocationSaveToggled(val),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MapMockupSection extends StatelessWidget {
  const _MapMockupSection({
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onCurrentLocationTap,
    required this.onDragEnd,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onCurrentLocationTap;
  final void Function(double lat, double lng) onDragEnd;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Google Map Background (ARCHITECTURE.md §3a)
          AppGoogleMap(
            initialLatitude: 24.7136,
            initialLongitude: 46.6753,
            onCameraMove: (pos) => onDragEnd(
              pos.target.latitude,
              pos.target.longitude,
            ),
            onTap: (latLng) => onDragEnd(
              latLng.latitude,
              latLng.longitude,
            ),
          ),

          // Central Pin and pulsing target
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(90),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Field floating at top
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: AppSpacing.sm,
            start: AppSpacing.md,
            end: AppSpacing.md,
            child: Material(
              elevation: 3,
              shadowColor: Colors.black26,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.md),
              ),
              child: AppTextField(
                key: const Key('location_search_input'),
                controller: searchController,
                hint: context.tr('location.search_hint'),
                textInputAction: TextInputAction.search,
                onChanged: onSearchChanged,
                onSubmitted: (_) => onSearchSubmitted(),
              ),
            ),
          ),

          // "موقعي الحالي" (Current Location) pill button
          Positioned.directional(
            textDirection: Directionality.of(context),
            bottom: AppSpacing.sm,
            end: AppSpacing.md,
            child: Material(
              color: AppColors.white,
              elevation: 3,
              shadowColor: Colors.black26,
              shape: const StadiumBorder(),
              child: InkWell(
                onTap: onCurrentLocationTap,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        context.tr('location.current_location'),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.ink,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
