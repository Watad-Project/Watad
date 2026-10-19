import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_earnings.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_offer.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_project.dart';

/// Aggregated data required by the contractor dashboard screen.
class ContractorDashboardData {
  const ContractorDashboardData({
    required this.profile,
    required this.earnings,
    required this.opportunitiesCount,
    required this.activeProjects,
    required this.myOffers,
  });

  final ContractorDashboardProfile profile;
  final ContractorDashboardEarnings earnings;
  final int opportunitiesCount;
  final List<ContractorDashboardProject> activeProjects;
  final List<ContractorDashboardOffer> myOffers;
}
