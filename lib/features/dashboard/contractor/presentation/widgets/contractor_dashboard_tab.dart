import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/features/dashboard/contractor/presentation/bloc/contractor_dashboard_bloc.dart';
import 'package:watad/features/dashboard/contractor/presentation/pages/contractor_dashboard_page.dart';

/// The contractor dashboard tab displayed in the bottom navigation.
class ContractorDashboardTab extends StatefulWidget {
  const ContractorDashboardTab({
    required this.bloc,
    this.onVerificationStatusTap,
    this.onBrowseOpportunities,
    this.onAllProjectsTap,
    this.onAllOffersTap,
    this.bell,
    super.key,
  });

  final ContractorDashboardBloc bloc;
  final VoidCallback? onVerificationStatusTap;
  final VoidCallback? onBrowseOpportunities;
  final VoidCallback? onAllProjectsTap;
  final VoidCallback? onAllOffersTap;

  /// The notifications bell, for the header.
  final Widget? bell;

  @override
  State<ContractorDashboardTab> createState() => _ContractorDashboardTabState();
}

class _ContractorDashboardTabState extends State<ContractorDashboardTab> {
  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: ContractorDashboardPage(
        bell: widget.bell,
        onVerificationStatusTap:
            widget.onVerificationStatusTap ??
            () => context.pushNamed(KycRoutes.statusName),
        onBrowseOpportunities:
            widget.onBrowseOpportunities ??
            () => context.goNamed(
              ContractorNavigationRoutes.navigationName,
              queryParameters: {'tab': 'contractor-work'},
            ),
        onAllProjectsTap:
            widget.onAllProjectsTap ??
            () => context.goNamed(
              ContractorNavigationRoutes.navigationName,
              queryParameters: {'tab': 'contractor-work'},
            ),
        onAllOffersTap:
            widget.onAllOffersTap ??
            () => context.goNamed(
              ContractorNavigationRoutes.navigationName,
              queryParameters: {'tab': 'contractor-work'},
            ),
      ),
    );
  }
}
